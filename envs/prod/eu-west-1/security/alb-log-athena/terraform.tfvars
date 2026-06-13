region      = "eu-west-1"
name_prefix = "prod"

database_name         = "prod_accesshub_logs"
table_name            = "alb_access_logs"
athena_workgroup_name = "prod-accesshub-alb-logs"

athena_results_prefix = "athena-results/alb-access-logs"

# Update this if older ALB access logs exist and should be queryable.
projection_start_date = "2026/06/01"

# 10 GiB per query. At Athena's $5/TB pricing, this caps a single query at about $0.05.
bytes_scanned_cutoff_per_query = 10737418240

create_reader_policy = true
reader_policy_name   = "prod-accesshub-alb-log-athena-reader"

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "alb-log-athena"
}
