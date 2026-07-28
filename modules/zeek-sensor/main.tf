##############################################################################
## Zeek network sensor + VPC Traffic Mirroring
##
## Instead of running Zeek on the EKS nodes (VPC CNI gives every pod its own
## ENI, so there is no single bridge to sniff), this deploys a dedicated Zeek
## sensor EC2 and mirrors the EKS worker-node ENIs into it via VPC Traffic
## Mirroring. Mirrored packets arrive VXLAN-encapsulated (UDP 4789) on the
## sensor's primary ENI, which Zeek listens on.
##
## The on-sensor Wazuh agent tails Zeek's http/dns/conn JSON logs and ships
## them to the Wazuh manager (Step 4 of the spec).
##############################################################################

data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ssm_parameter
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Zeek sensor: receives VXLAN-mirrored traffic, ships to Wazuh"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

# Mirrored traffic arrives VXLAN-encapsulated on UDP 4789 from source ENIs.
resource "aws_security_group_rule" "vxlan_in" {
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = "udp"
  from_port         = 4789
  to_port           = 4789
  cidr_blocks       = [var.vpc_cidr]
  description       = "VXLAN mirrored traffic from source ENIs"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.this.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All egress (incl. Wazuh manager 1514/1515)"
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive

    # --- Install Zeek (LTS) from the official openSUSE build repo ---------
    echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' \
      | tee /etc/apt/sources.list.d/security:zeek.list
    curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key \
      | gpg --dearmor | tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
    apt-get update -y
    apt-get install -y zeek-lts curl

    # --- Point Zeek at the mirror-target interface + JSON logs ------------
    sed -i "s/^interface=.*/interface=${var.capture_interface}/" /opt/zeek/etc/node.cfg || \
      echo "interface=${var.capture_interface}" >> /opt/zeek/etc/node.cfg
    grep -q 'json-logs.zeek' /opt/zeek/share/zeek/site/local.zeek || \
      echo '@load policy/tuning/json-logs.zeek' >> /opt/zeek/share/zeek/site/local.zeek

    export PATH="$PATH:/opt/zeek/bin"
    /opt/zeek/bin/zeekctl deploy

    # --- Install + enrol the Wazuh agent ---------------------------------
    curl -sO https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent.deb || true
    WAZUH_MANAGER="${var.wazuh_manager_ip}" apt-get install -y wazuh-agent || \
      { curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
        chmod 644 /usr/share/keyrings/wazuh.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list && \
        apt-get update -y && WAZUH_MANAGER="${var.wazuh_manager_ip}" apt-get install -y wazuh-agent; }

    # --- Tail Zeek's JSON logs (Step 4) ----------------------------------
    for logname in http dns conn; do
      if ! grep -q "/opt/zeek/logs/current/$logname.log" /var/ossec/etc/ossec.conf; then
        sed -i "/<\/ossec_config>/i \\  <localfile>\\n    <log_format>json</log_format>\\n    <location>/opt/zeek/logs/current/$logname.log</location>\\n  </localfile>" /var/ossec/etc/ossec.conf
      fi
    done

    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl restart wazuh-agent

    # --- Prune Zeek archives older than 48h (Step 5) ---------------------
    echo '0 * * * * root find /opt/zeek/logs/ -type f -mmin +2880 -delete' > /etc/cron.d/zeek-log-prune
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
  # Mirror targets must accept traffic destined for other MACs.
  source_dest_check = false
  user_data         = local.user_data

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

##############################
## VPC Traffic Mirroring    ##
##############################
resource "aws_ec2_traffic_mirror_target" "this" {
  description          = "${var.name} Zeek sensor"
  network_interface_id = aws_instance.this.primary_network_interface_id

  tags = merge(var.tags, { Name = "${var.name}-target" })
}

resource "aws_ec2_traffic_mirror_filter" "this" {
  description      = "${var.name} mirror all TCP/UDP/ICMP both directions"
  network_services = ["amazon-dns"]

  tags = merge(var.tags, { Name = "${var.name}-filter" })
}

resource "aws_ec2_traffic_mirror_filter_rule" "ingress" {
  description              = "all inbound"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_number              = 100
  rule_action              = "accept"
  traffic_direction        = "ingress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "egress" {
  description              = "all outbound"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_number              = 100
  rule_action              = "accept"
  traffic_direction        = "egress"
}

# One session per source ENI (EKS worker node primary ENIs).
resource "aws_ec2_traffic_mirror_session" "this" {
  for_each = {
    for idx, eni in var.source_network_interface_ids : format("%03d", idx + 1) => eni
  }

  description              = "${var.name} mirror ${each.value}"
  network_interface_id     = each.value
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.this.id
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  session_number           = tonumber(each.key)
  virtual_network_id       = var.traffic_mirror_vni

  tags = merge(var.tags, { Name = "${var.name}-session-${each.key}" })
}
