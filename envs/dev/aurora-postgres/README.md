# Aurora PostgreSQL (dev)

This stack deploys an Aurora PostgreSQL cluster into VPC `private_db_subnet_ids` and allows DB access from the VPC private-app security group from remote state.

## Usage

```bash
cd envs/dev/aurora-postgres
terraform init
terraform plan
terraform apply
```

## Notes

- Update `master_password` in `terraform.tfvars` before apply.
- By default, `skip_final_snapshot = false`; keep `final_snapshot_identifier` set.
