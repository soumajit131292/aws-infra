region       = "eu-west-1"
web_acl_name = "qa-accesshub-waf"
scope        = "REGIONAL"

log_retention_in_days = 30

tags = {
  env   = "qa"
  owner = "terraform-accesshub-platform"
}
