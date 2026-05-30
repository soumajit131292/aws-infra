region            = "eu-central-1"
web_acl_name      = "prod-dr-lb"
scope             = "REGIONAL"
waf_log_group_arn = "arn:aws:logs:eu-central-1:495711089104:log-group:aws-waf-logs-prod-dr-accesshub"
alb_resource_arn  = "arn:aws:elasticloadbalancing:eu-central-1:495711089104:loadbalancer/app/accesshub-prod-dr-alb/ab3211f49a034c9a"

# Keep false because association is currently managed via Helm chart annotation.
manage_alb_association = false

tags = {
  env   = "prod-dr"
  owner = "terraform-accesshub-platform"
}
