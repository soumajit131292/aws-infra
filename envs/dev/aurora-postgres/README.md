# Aurora PostgreSQL (dev)

This stack deploys an Aurora PostgreSQL cluster into VPC `private_db_subnet_ids` and allows DB access from the VPC private-app security group from remote state.

## Usage

```bash
cd aws-infra/envs/dev/aurora-postgres
terraform init
terraform plan
terraform apply
```

## Get Endpoint

Get writer endpoint from Terraform:

```bash
cd aws-infra/envs/dev/aurora-postgres
terraform output -raw cluster_endpoint
```

Optional reader endpoint:

```bash
terraform output -raw reader_endpoint
```

## Get Credentials From Secrets Manager

This stack is configured to read credentials from:

- `dev/aurora/app-credentials`

Get both values:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/aurora/app-credentials \
  --query SecretString \
  --output text
```

Extract username/password with `jq`:

```bash
SECRET_JSON="$(aws secretsmanager get-secret-value --secret-id dev/aurora/app-credentials --query SecretString --output text)"
DB_USER="$(echo "$SECRET_JSON" | jq -r '.username')"
DB_PASS="$(echo "$SECRET_JSON" | jq -r '.password')"
```

## Connect From Private Ubuntu VM (SSM)

Start SSM session:

```bash
aws ssm start-session --target <instance-id>
```

Install `psql` if needed:

```bash
sudo apt-get update -y && sudo apt-get install -y postgresql-client
```

Connect:

```bash
DB_HOST="$(cd envs/dev/aurora-postgres && terraform output -raw cluster_endpoint)"
DB_NAME="appdb"
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p 5432
```

## Connect From EKS Pod

Launch temporary PostgreSQL client pod:

```bash
kubectl run psql-client \
  --rm -it \
  --image=public.ecr.aws/docker/library/postgres:16 \
  --env="PGPASSWORD=$DB_PASS" \
  --command -- \
  psql -h <cluster-endpoint> -U "$DB_USER" -d appdb -p 5432
```

## Connection String

```text
postgresql://<username>:<password>@<cluster-endpoint>:5432/appdb
```

## Quick Troubleshooting

- `psql: could not translate host name`
  - Check DNS/VPC resolver and endpoint value.
- `connection timed out`
  - Verify source is in allowed SG/CIDR and route/NACL allow traffic.
- `password authentication failed`
  - Re-check secret content (`username`, `password` keys).
- `no pg_hba.conf entry`
  - Usually indicates wrong user/db or SSL/connection mode mismatch.

## Notes

- `terraform.tfvars` should use `db_credentials_secret_name`, not plain-text password.
- By default, `skip_final_snapshot = false`; keep `final_snapshot_identifier` set.
