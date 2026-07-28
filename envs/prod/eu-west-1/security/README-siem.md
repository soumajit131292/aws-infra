# Wazuh + Zeek SIEM stack — prod (eu-west-1)

Implements `SIEM_Stack_Deployment_Specification`, adapted to this environment's
reality (EKS managed node groups + Aurora, all-IaC) instead of the spec's
single Docker/Postgres host + manual console runbook.

## What was built

| Layer | Spec step | Here | Path |
|-------|-----------|------|------|
| Wazuh All-In-One server | Step 1 | Ubuntu 24.04 EC2 (`r6i.large`, private, SSM) + OSS installer in user_data + dedicated indexer EBS volume | `modules/wazuh-server`, `security/wazuh` |
| Agent on "container host" | Step 2 | **Wazuh agent DaemonSet** on EKS (nodes are ephemeral — a hand-install would not survive node recycling) | `security/wazuh/k8s/wazuh-agent-daemonset.yaml` |
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
WAZUH_IP=$(terraform -chdir=../wazuh output -raw wazuh_private_ip)
sed "s/REPLACE_WITH_WAZUH_PRIVATE_IP/$WAZUH_IP/" ../wazuh/k8s/wazuh-agent-daemonset.yaml | kubectl apply -f -
```

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
2. **OpenSearch ISM retention (Step 5)** — in the dashboard, Index Management →
   create an ISM policy transitioning/deleting indices after 7–14 days.
3. **Confirm agents enrolled** — dashboard → Agents (expect one per EKS node +
   the Zeek sensor).

## Cost note

This is a self-managed SIEM running **3 always-on EC2 instances** (Wazuh
`r6i.large` + Zeek `m5.large`, plus data EBS) — materially more than the
GuardDuty spend. It overlaps with GuardDuty on network/DNS detection but adds
log aggregation, dashboards, compliance, and custom rules that GuardDuty does
not provide.
