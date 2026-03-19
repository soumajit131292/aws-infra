# Route 53 Private DNS for Aurora RDS

This stack creates a private Route 53 hosted zone and CNAME records for Aurora PostgreSQL.
It is DR-ready: you get a stable app-facing DB record that can later be switched to DR by changing Terraform variables.

## Configure

Edit `terraform.tfvars`:

- `private_zone_name`: private hosted zone name, with trailing dot (example: `accesshub.internal.`)
- `rds_writer_record_name`: primary writer CNAME record (example: `db-primary.accesshub.internal`)
- `rds_active_record_name`: stable app-facing DB CNAME (example: `db.accesshub.internal`)
- `create_reader_record`: set `true` to also create reader endpoint CNAME
- `rds_reader_record_name`: reader CNAME record (example: `db-reader.accesshub.internal`)
- `record_ttl`: DNS TTL in seconds
- `create_dr_record`: keep `false` now, set `true` when DR endpoint exists
- `rds_dr_record_name`: DR writer CNAME name (example: `db-dr.accesshub.internal`)
- `rds_dr_endpoint`: DR RDS endpoint (empty for now)
- `route_active_to_dr`: keep `false` now; set `true` during DR failover to move `db.accesshub.internal` to DR

## Apply

```bash
terraform -chdir=envs/dev/route53-accesshub init
terraform -chdir=envs/dev/route53-accesshub plan
terraform -chdir=envs/dev/route53-accesshub apply
```
