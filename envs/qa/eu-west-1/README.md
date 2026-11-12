# QA environment — eu-west-1

Same region and account as prod, fully separate from it: own VPC, own state
keys, `qa-` names everywhere. No QA stack reads prod state.

## Stacks (mandatory)

| Stack | State key | Notes |
|-------|-----------|-------|
| `vpc` | `network/qa/eu-west-1/vpc/terraform.tfstate` | `10.40.0.0/16`, single NAT gateway |
| `eks` | `eks/qa/eu-west-1/control-plane/terraform.tfstate` | `qa-accesshub-cluster`, `m6i.large` core nodes, no spot runners, no EFS backup |
| `aurora-postgres` | `database/qa/eu-west-1/aurora-postgres/terraform.tfstate` | standalone (no global), 1 x `db.t4g.medium`, RDS Proxy, deletion protection off |

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

## Next (optional, not built yet)

EKS add-ons (alb-controller, external-secrets, argocd), ACM certificate
`qa-aws.accesshub-identity.com`, private zone `accesshub.internal` for the QA
VPC, GitHub OIDC role, WAF, jumphost, monitoring, Aurora alarms.
