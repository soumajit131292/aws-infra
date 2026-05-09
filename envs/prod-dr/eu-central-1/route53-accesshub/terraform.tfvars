region                 = "eu-central-1"
private_zone_name      = "accesshub.internal."
rds_writer_record_name = "db-primary.accesshub.internal"
rds_active_record_name = "db.accesshub.internal"
create_reader_record   = true
rds_reader_record_name = "db-reader.accesshub.internal"
record_ttl             = 60

# DR placeholders
create_dr_record       = false
rds_dr_record_name     = "db-dr.accesshub.internal"
rds_dr_endpoint        = ""
route_active_to_dr     = false
use_rds_proxy_endpoint = true

# ALB ingress DNS (disabled by default)
create_alb_record = false
alb_record_name   = "accesshub.accesshub.internal"
alb_dns_name      = ""
alb_zone_id       = ""
alb_name          = "accesshub-ai-prod-dr-alb"
