region = "eu-west-1"

# QA's own ALB access-log bucket: qa-accesshub-alb-access-logs-<account>-<region>.
create_alb_access_logs_bucket        = true
alb_access_logs_bucket_name_prefix   = "qa-accesshub-alb-access-logs"
alb_access_logs_bucket_force_destroy = true # QA can be torn down
alb_access_logs_retention_days       = 30

tags = {
  component = "alb-controller"
  env       = "qa"
}
