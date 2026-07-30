##############################################################################
## Wazuh All-In-One server (manager + indexer/OpenSearch + dashboard)
##
## Delivery: standard Ubuntu 24.04 AMI (same SSM-param pattern as
## ubuntu-private-vm) + the official Wazuh all-in-one installer run in
## user_data. No Marketplace subscription, fully IaC.
##
## A dedicated EBS data volume is mounted at the indexer data path so
## OpenSearch storage is separated from the root disk and independently
## sized. Access is private-only via SSM Session Manager (no public IP).
##############################################################################

data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ssm_parameter
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Wazuh server: dashboard 443, agent enrollment 1514/1515, SSH 22"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

# Dashboard (HTTPS) — admin CIDRs only
resource "aws_security_group_rule" "dashboard_https" {
  count             = length(var.admin_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.admin_cidrs
  description       = "Wazuh dashboard (admin)"
}

# SSH — admin CIDRs only (SSM is the primary path; this is a break-glass)
resource "aws_security_group_rule" "ssh" {
  count             = length(var.admin_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.admin_cidrs
  description       = "SSH (admin break-glass)"
}

# Agent enrollment (1515/tcp) + reporting (1514/tcp+udp) from in-VPC agents
resource "aws_security_group_rule" "agent_enroll_tcp" {
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = "tcp"
  from_port         = 1514
  to_port           = 1515
  cidr_blocks       = var.agent_source_cidrs
  description       = "Wazuh agent enrollment + reporting (TCP)"
}

resource "aws_security_group_rule" "agent_report_udp" {
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = "udp"
  from_port         = 1514
  to_port           = 1514
  cidr_blocks       = var.agent_source_cidrs
  description       = "Wazuh agent reporting (UDP)"
}

resource "aws_security_group_rule" "agent_from_sgs" {
  for_each                 = toset(var.agent_source_security_group_ids)
  type                     = "ingress"
  security_group_id        = aws_security_group.this.id
  protocol                 = "tcp"
  from_port                = 1514
  to_port                  = 1515
  source_security_group_id = each.value
  description              = "Wazuh agent enrollment + reporting from SG ${each.value}"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.this.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All egress"
}

locals {
  # Runs on first boot: mount the data volume at the indexer data path, then
  # run the official Wazuh all-in-one installer. -i skips the hardware check
  # (we are intentionally on a 2 vCPU node); -o overwrites a partial install.
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    INDEXER_DATA_DIR="/var/lib/wazuh-indexer"

    # --- Locate + mount the dedicated data volume -------------------------
    # On Nitro (r6i) the extra EBS disk shows up as an unmounted nvme disk
    # with no partitions. The volume attaches shortly after boot, so poll for
    # it (up to ~2 min) before giving up. Pick the first data disk that is
    # not the root disk and has no filesystem/mountpoint.
    ROOT_DISK="$(lsblk -dno PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null || true)"
    DATA_DEV=""
    for _ in $(seq 1 24); do
      for d in $(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1}'); do
        if [ "/dev/$d" != "/dev/$ROOT_DISK" ] && [ -z "$(lsblk -no MOUNTPOINT /dev/$d | tr -d ' ')" ]; then
          DATA_DEV="/dev/$d"; break
        fi
      done
      [ -n "$DATA_DEV" ] && break
      sleep 5
    done

    if [ -n "$DATA_DEV" ]; then
      if ! blkid "$DATA_DEV"; then
        mkfs.xfs "$DATA_DEV"
      fi
      mkdir -p "$INDEXER_DATA_DIR"
      UUID="$(blkid -s UUID -o value "$DATA_DEV")"
      grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $INDEXER_DATA_DIR xfs defaults,nofail 0 2" >> /etc/fstab
      mount -a
    fi

    # --- Install Wazuh all-in-one ----------------------------------------
    cd /root
    curl -sO "https://packages.wazuh.com/${var.wazuh_version}/wazuh-install.sh"
    bash ./wazuh-install.sh -a -i -o

    # Credentials are written to /root/wazuh-install-files.tar by the installer.
    # Retrieve them over SSM: sudo tar -xf /root/wazuh-install-files.tar -O wazuh-install-files/wazuh-passwords.txt

    # --- Raw archive visibility for Zeek/searchable low-severity events ----
    if [ "${var.enable_logall_json}" = "true" ]; then
      sed -i 's|<logall_json>no</logall_json>|<logall_json>yes</logall_json>|' /var/ossec/etc/ossec.conf
    fi

    if [ "${var.enable_archive_indexing}" = "true" ]; then
      sed -i '/archives:/,/^[^[:space:]]/ s/enabled: false/enabled: true/' /etc/filebeat/filebeat.yml
    fi

    # --- Index retention: delete Wazuh indices after N days (ISM policy) ---
    # Best-effort; runs after install once the indexer is answering. The
    # ism_template auto-attaches the policy to new wazuh-* indices.
    ADMIN_PW="$(tar -xOf /root/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt | grep -A1 "indexer_username: 'admin'" | grep -m1 'indexer_password' | sed "s/.*: '//; s/'.*//")"
    for _ in $(seq 1 60); do
      curl -sk -u "admin:$ADMIN_PW" https://localhost:9200/_cluster/health >/dev/null && break
      sleep 10
    done
    curl -sk -u "admin:$ADMIN_PW" -X PUT \
      "https://localhost:9200/_plugins/_ism/policies/wazuh-retention" \
      -H 'Content-Type: application/json' \
      -d '{"policy":{"description":"Delete Wazuh indices after ${var.retention_days} days","default_state":"hot","states":[{"name":"hot","actions":[],"transitions":[{"state_name":"delete","conditions":{"min_index_age":"${var.retention_days}d"}}]},{"name":"delete","actions":[{"delete":{}}],"transitions":[]}],"ism_template":[{"index_patterns":["wazuh-alerts-*","wazuh-archives-*"],"priority":100}]}}' || true

    systemctl restart wazuh-manager || true
    systemctl restart filebeat || true
  EOT
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  iam_instance_profile        = var.instance_profile_name
  key_name                    = var.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = local.user_data

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ebs_volume" "indexer_data" {
  availability_zone = aws_instance.this.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = true

  tags = merge(var.tags, { Name = "${var.name}-indexer-data" })
}

resource "aws_volume_attachment" "indexer_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.indexer_data.id
  instance_id = aws_instance.this.id
}

resource "aws_ssm_association" "archive_visibility" {
  count = var.enable_logall_json || var.enable_archive_indexing ? 1 : 0

  name = "AWS-RunShellScript"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  parameters = {
    commands = <<-EOC
      set -euxo pipefail

      if [ "${var.enable_logall_json}" = "true" ]; then
        sed -i 's|<logall_json>no</logall_json>|<logall_json>yes</logall_json>|' /var/ossec/etc/ossec.conf
      fi

      if [ "${var.enable_archive_indexing}" = "true" ]; then
        sed -i '/archives:/,/^[^[:space:]]/ s/enabled: false/enabled: true/' /etc/filebeat/filebeat.yml
      fi

      systemctl restart wazuh-manager
      systemctl restart filebeat
      EOC
  }
}
