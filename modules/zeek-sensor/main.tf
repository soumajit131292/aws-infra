##############################################################################
## Zeek network sensor + VPC Traffic Mirroring
##
## Instead of running Zeek on the EKS nodes (VPC CNI gives every pod its own
## ENI, so there is no single bridge to sniff), this deploys a dedicated Zeek
## sensor EC2 and mirrors the EKS worker-node ENIs into it via VPC Traffic
## Mirroring. Mirrored packets arrive VXLAN-encapsulated (UDP 4789) on the
## sensor's primary ENI, which Zeek listens on.
##
## The on-sensor Wazuh agent tails Zeek's JSON logs (zeek_log_files) and ships
## them to the Wazuh manager (Step 4 of the spec).
##
## user_data only installs Zeek + a version-pinned Wazuh agent on first boot.
## Everything that must stay correct on the running sensor (manager IP, agent
## version, log list, Zeek auto-restart, log pruning) is in local.sensor_config,
## applied over SSM by aws_ssm_association.sensor_config.
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
  wazuh_agent_name = coalesce(var.wazuh_agent_name, var.name)

  # Wazuh <localfile> blocks for the Zeek logs. One wildcard per log so a file
  # Zeek has not created yet is rescanned instead of erroring (Zeek writes
  # dns.log, http.log, notice.log ... only after their first event). The
  # exclude skips the dated copies rotation leaves briefly in current/
  # (conn.2026-...log), which would otherwise ship an hour of events twice.
  zeek_localfiles = join("\n", [
    for name in var.zeek_log_files : <<-XML
      <localfile>
        <log_format>json</log_format>
        <location>/opt/zeek/logs/current/${name}*.log</location>
        <exclude>/opt/zeek/logs/current/${name}.*.log</exclude>
      </localfile>
    XML
  ])

  # Converges a running sensor (applied by aws_ssm_association.sensor_config,
  # re-run whenever this text changes). Idempotent; no instance restart.
  sensor_config = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    OSSEC=/var/ossec/etc/ossec.conf

    # Wait for user_data on a fresh instance (Zeek + Wazuh agent installed).
    for _ in $(seq 1 60); do
      [ -f "$OSSEC" ] && [ -x /opt/zeek/bin/zeekctl ] && break
      sleep 20
    done
    [ -f "$OSSEC" ] || { echo "wazuh-agent not installed after 20 min" >&2; exit 1; }

    # --- Pin the agent version (must not be newer than the manager) -------
    apt-mark unhold wazuh-agent >/dev/null 2>&1 || true
    if [ "$(dpkg-query -W -f='$${Version}' wazuh-agent 2>/dev/null)" != "${var.wazuh_agent_version}" ]; then
      apt-get update -y
      apt-get install -y --allow-downgrades "wazuh-agent=${var.wazuh_agent_version}"
    fi
    apt-mark hold wazuh-agent

    # --- Manager address (follows the Wazuh server's current IP) ----------
    sed -i '/<client>/,/<\/client>/ s|<address>[^<]*</address>|<address>${var.wazuh_manager_ip}</address>|' "$OSSEC"

    # --- Zeek log collection: one managed block, no duplicates -------------
    # Drop every per-file Zeek <localfile> (incl. the duplicates the old
    # user_data + association added) and any previous managed block.
    python3 - "$OSSEC" <<'PY'
    import re, sys
    p = sys.argv[1]
    s = open(p).read()
    s = re.sub(r'\n?[ \t]*<!-- BEGIN zeek-logs -->.*?<!-- END zeek-logs -->\n?', '\n', s, flags=re.S)
    s = re.sub(r'\n?[ \t]*<localfile>\s*<log_format>json</log_format>\s*<location>/opt/zeek/logs/current/[^<]*</location>\s*</localfile>', '', s)
    open(p, 'w').write(s)
    PY
    cat > /tmp/zeek-localfiles.xml <<'XML'
      <!-- BEGIN zeek-logs -->
    ${local.zeek_localfiles}
      <!-- END zeek-logs -->
    XML
    python3 - "$OSSEC" /tmp/zeek-localfiles.xml <<'PY'
    import sys
    p, blk = sys.argv[1], open(sys.argv[2]).read()
    s = open(p).read()
    i = s.rfind('</ossec_config>')
    s = s[:i] + blk + s[i:]
    open(p, 'w').write(s)
    PY
    rm -f /tmp/zeek-localfiles.xml

    # --- Enroll only if this sensor has no key yet -------------------------
    # (Re-running agent-auth while registered fails with "Duplicate agent name".)
    if ! grep -q " ${local.wazuh_agent_name} " /var/ossec/etc/client.keys 2>/dev/null; then
      for _ in $(seq 1 30); do
        /var/ossec/bin/agent-auth -m "${var.wazuh_manager_ip}" -A "${local.wazuh_agent_name}" && break
        sleep 10
      done
    fi

    systemctl enable wazuh-agent
    systemctl restart wazuh-agent

    # --- Zeek: restart it if it crashes ------------------------------------
    # zeekctl cron restarts crashed nodes and does log housekeeping; without it
    # a crashed Zeek stays down until someone runs `zeekctl deploy`.
    echo '*/5 * * * * root /opt/zeek/bin/zeekctl cron' > /etc/cron.d/zeekctl-cron
    chmod 644 /etc/cron.d/zeekctl-cron
    if ! /opt/zeek/bin/zeekctl status | grep -q running; then
      /opt/zeek/bin/zeekctl deploy
    fi

    # --- Prune archived Zeek logs older than 48h ---------------------------
    # Only the dated archive dirs; never the live logs/current/ (a quiet log
    # there can be older than 48h while Zeek is still writing to it).
    echo '0 * * * * root find /opt/zeek/logs/ -mindepth 1 -maxdepth 1 -type d -name "20*" -mmin +2880 -exec rm -rf {} +' > /etc/cron.d/zeek-log-prune
    chmod 644 /etc/cron.d/zeek-log-prune
  EOT

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

    # --- Install the Wazuh agent (version-pinned; config + enrollment are
    # done by aws_ssm_association.sensor_config) ---------------------------
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
    chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
    apt-get update -y
    apt-get install -y "wazuh-agent=${var.wazuh_agent_version}"
    apt-mark hold wazuh-agent
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

  # user_data only runs on first boot, so editing it never changes a running
  # sensor — it only stops/starts it. Ongoing config (manager IP, agent
  # version, log list, crons) is applied by aws_ssm_association.sensor_config.
  # ami: the SSM parameter tracks Ubuntu's "current" image, which moves on
  # every Canonical release and would otherwise force a rebuild.
  # To rebuild deliberately: terraform apply -replace=<this resource>.
  lifecycle {
    ignore_changes = [ami, user_data]
  }

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

# Desired-state config for the sensor, applied over SSM so it reaches the
# running instance. It re-runs whenever the script changes (new manager IP,
# agent version, log list) and is safe to re-run.
resource "aws_ssm_association" "sensor_config" {
  name             = "AWS-RunShellScript"
  association_name = "${var.name}-sensor-config"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  parameters = {
    commands         = local.sensor_config
    executionTimeout = "1800"
  }
}
