dr_region     = "eu-central-1"
source_region = "eu-west-1"
name_prefix   = "prod-dr-failover"

# Public health check on prod ALB (where the Route 53 health check + CW alarm point)
public_health_check_endpoint = "prod-aws.accesshub-identity.com"
public_health_check_url      = "https://prod-aws.accesshub-identity.com/health"

# Optional: existing R53 health check on PROD-DR ALB used in post-failover validation.
# Fill in once you have it (or leave empty to skip that validation check).
r53_dr_health_check_id = ""

# Tier-1 alarm thresholds + Phase 1 (M-of-N) tuning
prod_alb_name           = "accesshub-prod-alb"
prod_cluster_identifier = "prod-aurora-postgres"
dr_cluster_identifier   = "prod-dr-aurora-postgres"

# Static thresholds (per-alarm)
alb_5xx_threshold                   = 50
aurora_replication_lag_threshold_ms = 60000
aurora_min_connections              = 1
aurora_db_load_threshold            = 4
efs_replication_lag_threshold_sec   = 600

# Phase 1 — Window (N periods) and M-of-N (datapoints_to_alarm) per alarm.
# Larger windows + M < N = more tolerant to deployment-window flapping.

# Route 53 unhealthy: 3 bad minutes within any 5-min window
cw_alarm_evaluation_periods  = 5
cw_alarm_datapoints_to_alarm = 3

# ALB UnHealthyHosts: 7 bad minutes within any 10-min window
alb_unhealthy_evaluation_periods  = 10
alb_unhealthy_datapoints_to_alarm = 7

# ALB 5xx: 5 high-error minutes within any 10-min window
alb_5xx_evaluation_periods  = 10
alb_5xx_datapoints_to_alarm = 5

# Aurora replication lag: 3 bad minutes within any 5-min window
aurora_replication_lag_evaluation_periods  = 5
aurora_replication_lag_datapoints_to_alarm = 3

# Aurora no-connections: 7 connection-less minutes within any 10-min window
aurora_no_connections_evaluation_periods  = 10
aurora_no_connections_datapoints_to_alarm = 7

# Aurora DBLoad: 7 high-load minutes within any 10-min window
aurora_db_load_evaluation_periods  = 10
aurora_db_load_datapoints_to_alarm = 7

# EFS replication lag: 3 stale-sync minutes within any 5-min window
efs_replication_lag_evaluation_periods  = 5
efs_replication_lag_datapoints_to_alarm = 3

# Scale targets at failover
target_node_desired = 3
target_node_max     = 5
target_app_replicas = 3

# Approval gate (1 hour timeout, must approve via SNS link)
# IMPORTANT: rotate this periodically and update SNS subscribers.
approval_shared_secret   = "CHANGEME-32-char-random-string-here-XXXXXX"
approval_timeout_seconds = 3600

# Phase 2 — alarm suppression during ArgoCD deployments
# Same value goes into the ArgoCD Notifications ConfigMap as $hmac-shared-secret.
# Rotate together. Leave empty to disable signature verification (NOT recommended).
argocd_webhook_secret             = "CHANGEME-32-char-random-string-for-webhook"
alarm_suppression_max_age_seconds = 2700 # 45 min — should exceed your longest deploy

# Notification subscribers — email-only.
# Add your 2 email addresses below.
alert_email_subscribers = [
  "oncall@accesshub.example",
]

# GitHub PAT for replica scaling — secret must exist before apply.
# Create it manually:
#   aws secretsmanager create-secret \
#     --region eu-central-1 \
#     --name prod-dr/dr-failover/github-pat \
#     --secret-string '{"token":"ghp_xxxxxxxxxxxx"}'
# Then paste the resulting ARN here.
github_pat_secret_arn = "arn:aws:secretsmanager:eu-central-1:495711089104:secret:prod-dr/dr-failover/github-pat-XXXXXX"

github_owner       = "soumajit131292"
github_repo        = "aws-infra"
github_branch      = "main"
github_values_path = "helm-charts/helm/accesshub/values-prod-dr.yaml"

# Private DNS record names — MUST match what's in route53-accesshub tfvars.
rds_active_record_name = "db.accesshub.internal"
rds_dr_record_name     = "db-dr.accesshub.internal"
record_ttl             = 60

tags = {
  Environment = "prod-dr"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "dr-failover-orchestration"
}
