# Wazuh + Zeek SIEM stack — prod (eu-west-1)

Implements `SIEM_Stack_Deployment_Specification`, adapted to this environment's
reality (EKS managed node groups + Aurora, all-IaC) instead of the spec's
single Docker/Postgres host + manual console runbook.

## What was built

| Layer | Spec step | Here | Path |
|-------|-----------|------|------|
| Wazuh All-In-One server | Step 1 | Ubuntu 24.04 EC2 (`r6i.large`, private, SSM) + OSS installer in user_data + dedicated indexer EBS volume | `modules/wazuh-server`, `security/wazuh` |
| Agent on "container host" | Step 2 | **Wazuh agent DaemonSet** on EKS via a vendored Helm chart (nodes are ephemeral — a hand-install would not survive node recycling). Long-disconnected agents of scaled-in/replaced nodes are auto-removed on the manager | `modules/eks-wazuh-agent`, `eks-add-on/wazuh-agent`; cleanup in `modules/wazuh-server/agent-maintenance.tf` |
| Zeek network sensor | Step 3 | **Dedicated Zeek EC2 + VPC Traffic Mirroring** of node ENIs (VPC CNI has no single bridge to sniff on-node) | `modules/zeek-sensor`, `security/zeek-sensor` |
| Zeek logs → Wazuh | Step 4 | On-sensor Wazuh agent tails http/dns/conn JSON logs | in `modules/zeek-sensor` user_data |
| Sizing / retention | Step 5 | Zeek 48h log-prune cron (automated); OpenSearch ISM = manual, see below | — |

### Deviations from the spec (by design)
- **Aurora is managed** — no host to install an agent on. DB coverage = GuardDuty
  RDS Protection (already deployed) + optionally exporting Aurora Postgres logs
  to Wazuh later. The spec's "Postgres container host agent" does not apply.
- **Zeek is off-node** via Traffic Mirroring rather than on the nodes.
- **Marketplace AMI not used** — OSS installer keeps it fully IaC.

## Apply order

```bash
# 1. Wazuh server first (Zeek sensor depends on its private IP via remote state)
cd envs/prod/eu-west-1/security/wazuh
#   -> set admin_cidrs in terraform.tfvars to your VPN/bastion ranges first
terraform init && terraform apply

# 2. Zeek sensor
cd ../zeek-sensor
#   -> populate source_network_interface_ids (see below)
terraform init && terraform apply

# 3. Wazuh agent DaemonSet on EKS
#   a) mirror the agent image to ECR (from the repo root)
./envs/prod/eu-west-1/eks-add-on/wazuh-agent/scripts/mirror-images-to-ecr.sh
#   b) install (manager IP is read from the wazuh stack's remote state)
cd ../../eks-add-on/wazuh-agent
terraform init && terraform apply
```

The `eks-prod` agent group and the disconnected-agent cleanup cron are created
on the manager by step 1 (`enable_agent_cleanup = true`, applied over SSM).
Check what the cleanup would remove without deleting anything:

```bash
sudo /usr/local/sbin/wazuh-agent-cleanup.sh --dry-run
```

## Upgrading the Wazuh server (rebuild) — 4.9 → 4.14.10

The server is installed by user_data, which only runs on first boot, so
changing `wazuh_version` does **not** upgrade a running server. The upgrade is a
clean rebuild with the new installer (`packages.wazuh.com/4.14/wazuh-install.sh`
pins **4.14.10**; the matching agent image is `wazuh/wazuh-agent:4.14.10`).
This **discards the existing indices** — acceptable here because the SIEM is not
in use yet. For an in-use server, follow Wazuh's in-place upgrade guide instead.

The private IP is pinned (`wazuh_private_ip`) so the rebuilt server keeps the
address the Zeek and EKS agents report to.

```bash
cd envs/prod/eu-west-1/security/wazuh

# 1. Pin the CURRENT IP: put this value in terraform.tfvars -> wazuh_private_ip
terraform output -raw wazuh_private_ip

# 2. Review. A plain plan shows an in-place update of the instance (user_data
#    changed) — do NOT apply that; it only stops/starts the VM.
terraform plan

# 3. Rebuild instance + indexer volume with the 4.14 installer
terraform apply \
  -replace='module.wazuh.aws_instance.this' \
  -replace='module.wazuh.aws_ebs_volume.indexer_data'
```

After apply (the installer takes ~15–20 min), on the server via SSM:

```bash
sudo tail -f /var/log/cloud-init-output.log          # wait for the installer to finish
sudo /var/ossec/bin/wazuh-control info               # WAZUH_VERSION="v4.14.10"
systemctl is-active wazuh-manager wazuh-indexer wazuh-dashboard filebeat
sudo tar -xOf /root/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt   # new admin password
```

The new manager has no key for the Zeek sensor, so re-enroll it (on the Zeek
sensor via SSM). The agent must not be newer than the manager:

```bash
sudo /var/ossec/bin/wazuh-control info               # must be <= v4.14.10
sudo /var/ossec/bin/agent-auth -m <wazuh_private_ip> -A prod-zeek-sensor
sudo systemctl restart wazuh-agent
```

## Zeek sensor config (applied over SSM)

`aws_ssm_association.sensor_config` (in `modules/zeek-sensor`) converges the
running sensor; it re-runs whenever its script changes and is safe to re-run:

- points the agent at the Wazuh server's current IP (from the wazuh stack's
  remote state) and enrolls it only if it has no key yet
- pins `wazuh-agent` to `wazuh_agent_version` and holds the package
- ships `conn dns http ssl notice weird` (`zeek_log_files`) as one managed block
- `zeekctl cron` every 5 min, so a crashed Zeek restarts on its own
- prunes dated archive dirs older than 48h (never `logs/current/`)

The instance ignores `user_data` changes (it only runs on first boot), so a
new Wazuh server IP no longer stops/starts the sensor. Check the last run:
AWS Console → Systems Manager → State Manager → `prod-zeek-sensor-sensor-config`.

## Discover EKS node ENIs for mirroring (Zeek sensor input)

Managed-node-group instances are ephemeral, so refresh this list after scaling
or node replacement (or automate via a tag-driven Lambda):

```bash
aws ec2 describe-instances --region eu-west-1 \
  --filters "Name=tag:eks:cluster-name,Values=prod-accesshub-cluster" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].NetworkInterfaces[?Attachment.DeviceIndex==\`0\`].NetworkInterfaceId" \
  --output text
```

Put the IDs into `zeek-sensor/terraform.tfvars` → `source_network_interface_ids`.

## Remaining manual steps (not IaC-able)

1. **Dashboard credentials** — the installer writes them on the server:
   ```bash
   aws ssm start-session --target <wazuh_instance_id> --region eu-west-1
   sudo tar -xf /root/wazuh-install-files.tar -O wazuh-install-files/wazuh-passwords.txt
   ```
2. **Confirm agents enrolled** — dashboard → Agents (expect one per EKS node +
   the Zeek sensor).

## Cost note

This is a self-managed SIEM running **3 always-on EC2 instances** (Wazuh
`r6i.large` + Zeek `m5.large`, plus data EBS) — materially more than the
GuardDuty spend. It overlaps with GuardDuty on network/DNS detection but adds
log aggregation, dashboards, compliance, and custom rules that GuardDuty does
not provide.
