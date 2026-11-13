# QA environment — eu-west-1

Same region and account as prod, fully separate from it: own VPC, own state
keys, `qa-` names everywhere. No QA stack reads prod state.

## Stacks (mandatory)

| Stack | State key | Notes |
|-------|-----------|-------|
| `vpc` | `network/qa/eu-west-1/vpc/terraform.tfstate` | `10.40.0.0/16`, single NAT gateway |
| `eks` | `eks/qa/eu-west-1/control-plane/terraform.tfstate` | `qa-accesshub-cluster`, `m6i.large` core nodes, no spot runners, no EFS backup |
| `aurora-postgres` | `database/qa/eu-west-1/aurora-postgres/terraform.tfstate` | standalone (no global), 1 x `db.t4g.medium`, RDS Proxy, deletion protection off |
| `ubuntu-jumphost-vm` | `compute/qa/eu-west-1/ubuntu-jumphost-vm/terraform.tfstate` | `qa-ubuntu-jumphost`, `t3.small`, private, SSM only |
| `acm/accesshub-identity` | `acm/qa/eu-west-1/accesshub-identity/terraform.tfstate` | `qa.accesshub-identity.com`, DNS-validated in the public zone `accesshub-identity.com` |
| `route53-accesshub` | `dns/qa/eu-west-1/route53-accesshub/terraform.tfstate` | Private zone `accesshub.internal` on the **QA VPC only**: `db-primary` → QA RDS Proxy, `db` → `db-primary`, `db-reader` → QA reader |
| `waf-accesshub` | `waf/qa/eu-west-1/accesshub/terraform.tfstate` | `qa-accesshub-waf`, same 7 AWS managed rule groups as prod; own log group `aws-waf-logs-qa-accesshub-waf` |

## Jumphost (the only way into the QA cluster)

The QA EKS API endpoint is private and the QA VPC is not peered with prod, so
`kubectl`, `helm` and the add-on Terraform stacks run from the QA jumphost.

1. Apply `ubuntu-jumphost-vm`.
2. Re-apply `eks`. It adds an access entry giving the jumphost's role
   (`qa-eu-west-1-vpc-ec2-ssm-role`) cluster-admin on the QA cluster only.
3. Install tools with Ansible (always limit to QA):
   ```bash
   cd ansible
   ansible env_qa -m ping
   ansible-playbook playbook-tools.yml --limit env_qa
   ```
4. On the jumphost (via SSM):
   ```bash
   aws eks update-kubeconfig --region eu-west-1 --name qa-accesshub-cluster
   kubectl get nodes
   ```

## Differences from prod

| | prod | QA |
|---|---|---|
| VPC CIDR | `10.20.0.0/16` | `10.40.0.0/16` (dev 10.10, prod-dr 10.30) |
| NAT gateways | 1 per AZ | 1 shared (`single_nat_gateway = true`) |
| Core nodes | `m6i.xlarge` | `m6i.large` |
| Spot runner node group | on | off |
| EFS backup | on | off |
| Aurora | 2 x `db.r6g.large`, Global Database | 1 x `db.t4g.medium`, standalone |
| Aurora deletion protection / final snapshot | on / kept | off / skipped |
| Log retention (EKS, flow logs, Aurora) | 365 days | 30 days |
| Aurora backups | 7 days | 1 day |

## Prerequisite: DB credentials secret

The Aurora stack reads the master credentials from Secrets Manager. Create
QA's own secret first (never reuse the prod one):

```bash
aws secretsmanager create-secret --region eu-west-1 \
  --name qa/aurora/app-credentials \
  --secret-string '{"username":"app_user","password":"<generate-a-strong-password>"}'
```

## Apply order

Each stack depends on the one before it through remote state.

```bash
cd envs/qa/eu-west-1/vpc             && terraform init && terraform plan && terraform apply
cd ../eks                            && terraform init && terraform plan && terraform apply
cd ../aurora-postgres                && terraform init && terraform plan && terraform apply
```

Before each apply, confirm the plan only creates `qa-*` resources and shows
`0 to change, 0 to destroy` on a first run.

## Shared with prod (account/region level, nothing to create)

- GuardDuty detector — covers QA automatically. Runtime Monitoring's EKS add-on
  auto-management also installs the GuardDuty agent on the QA cluster (extra cost).
- ECR repositories (`thirdparty/*` mirrors, app images)
- CloudTrail, IAM Identity Center
- Terraform state bucket (separate keys)

## Not in QA

Aurora Global Database, EFS replication, DR (prod-dr, dr-failover), Wazuh,
Zeek, security log pipeline, ALB log Athena.

## EKS add-ons (`eks-add-on/`)

These call the cluster API, so apply them **from the QA jumphost**, in order:

| Stack | State key | QA specifics |
|-------|-----------|--------------|
| `alb-controller` | `eks-add-on/qa/eu-west-1/alb-controller/terraform.tfstate` | IRSA role `qa-accesshub-cluster-alb-controller`; own log bucket `qa-accesshub-alb-access-logs-<acct>-<region>` |
| `external-secrets` | `eks-add-on/qa/eu-west-1/external-secrets/terraform.tfstate` | Reads **`qa/*` secrets only** (validation blocks `*` and prod ARNs) |
| `argocd` | `eks-add-on/qa/eu-west-1/argocd/terraform.tfstate` | Same as prod (internet-facing ALB + WAF), with QA's own WAF and ALB `qa-argocd-alb` / group `qa-argocd`. Apply `waf-accesshub` first |

Apply `waf-accesshub` before `argocd` (argocd reads the QA web ACL ARN from its state).

Images come from the existing `thirdparty/*` ECR mirrors (same account and
region), so nothing needs mirroring for QA.

## Next — required before the app can run (not built yet)

Public DNS record `qa.accesshub-identity.com` → QA app ALB (after the app's
ALB exists), `values-qa.yaml` and the QA Argo CD application.

## Optional (not built yet)

GitHub OIDC role, monitoring, Aurora alarms.
