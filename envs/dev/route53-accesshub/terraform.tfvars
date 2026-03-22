region                 = "us-east-1"
private_zone_name      = "accesshub.internal."
rds_writer_record_name = "db-primary.accesshub.internal"
rds_active_record_name = "db.accesshub.internal"
create_reader_record   = true
rds_reader_record_name = "db-reader.accesshub.internal"
record_ttl             = 60

# DR placeholders (keep disabled until DR exists)
create_dr_record   = false
rds_dr_record_name = "db-dr.accesshub.internal"
rds_dr_endpoint    = ""
route_active_to_dr = false

# ALB ingress DNS (disabled by default)
create_alb_record = false
alb_record_name   = "accesshub.accesshub.internal"
alb_dns_name      = ""
alb_zone_id       = ""
alb_name          = "accesshub-dev-alb"

# PUBLIC ALB DNS (requires an existing public hosted zone / registered domain)
create_public_alb_record = true
public_hosted_zone_name  = "accesshub-ai.com."
public_hosted_zone_id    = ""
public_alb_record_name   = "dev.accesshub-ai.com."
