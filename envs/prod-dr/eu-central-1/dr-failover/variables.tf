variable "dr_region" {
  description = "DR AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "name_prefix" {
  type    = string
  default = "prod-dr-failover"
}

variable "source_region" {
  type    = string
  default = "eu-west-1"
}

# Public health check + DR validation
variable "public_health_check_endpoint" {
  description = "Public ALB hostname for the Route 53 health check (no scheme)."
  type        = string
  default     = "prod-aws.accesshub-identity.com"
}

variable "public_health_check_url" {
  description = "Full URL for post-failover validation (https + path)."
  type        = string
  default     = "https://prod-aws.accesshub-identity.com/health"
}

variable "r53_dr_health_check_id" {
  description = "Optional Route 53 health check ID for the prod-dr ALB (validation step). Leave empty to skip."
  type        = string
  default     = ""
}

# Tier-1 alarm inputs — ALB
variable "prod_alb_name" {
  description = "Name of the prod ALB. Match the value of alb.ingress.kubernetes.io/load-balancer-name annotation."
  type        = string
  default     = "accesshub-prod-alb"
}

variable "alb_5xx_threshold" {
  type    = number
  default = 50
}

# Tier-1 alarm inputs — Aurora
variable "prod_cluster_identifier" {
  type    = string
  default = "prod-aurora-postgres"
}

variable "dr_cluster_identifier" {
  type    = string
  default = "prod-dr-aurora-postgres"
}

variable "aurora_replication_lag_threshold_ms" {
  description = "Alarm threshold in milliseconds for Aurora Global DB replication lag."
  type        = number
  default     = 60000
}

variable "aurora_min_connections" {
  description = "Minimum sustained DatabaseConnections on prod cluster (0 disables this alarm)."
  type        = number
  default     = 1
}

# Tier-1 alarm inputs — EFS
variable "efs_replication_lag_threshold_sec" {
  description = "Alarm if EFS TimeSinceLastSync on the destination exceeds this many seconds."
  type        = number
  default     = 600
}

# Phase 1 — eval-window + M-of-N tuning (passes through to module)
variable "cw_alarm_evaluation_periods" {
  type    = number
  default = 5
}

variable "cw_alarm_datapoints_to_alarm" {
  type    = number
  default = 3
}

variable "alb_unhealthy_evaluation_periods" {
  type    = number
  default = 10
}

variable "alb_unhealthy_datapoints_to_alarm" {
  type    = number
  default = 7
}

variable "alb_5xx_evaluation_periods" {
  type    = number
  default = 10
}

variable "alb_5xx_datapoints_to_alarm" {
  type    = number
  default = 5
}

variable "aurora_replication_lag_evaluation_periods" {
  type    = number
  default = 5
}

variable "aurora_replication_lag_datapoints_to_alarm" {
  type    = number
  default = 3
}

variable "aurora_no_connections_evaluation_periods" {
  type    = number
  default = 10
}

variable "aurora_no_connections_datapoints_to_alarm" {
  type    = number
  default = 7
}

variable "aurora_db_load_threshold" {
  type    = number
  default = 4
}

variable "aurora_db_load_evaluation_periods" {
  type    = number
  default = 10
}

variable "aurora_db_load_datapoints_to_alarm" {
  type    = number
  default = 7
}

variable "efs_replication_lag_evaluation_periods" {
  type    = number
  default = 5
}

variable "efs_replication_lag_datapoints_to_alarm" {
  type    = number
  default = 3
}

# Scale targets
variable "target_node_desired" {
  type    = number
  default = 3
}

variable "target_node_max" {
  type    = number
  default = 5
}

variable "target_app_replicas" {
  type    = number
  default = 3
}

# Phase 2: alarm suppression
variable "argocd_webhook_secret" {
  description = "HMAC shared secret for ArgoCD -> webhook signature verification."
  type        = string
  sensitive   = true
  default     = ""
}

variable "alarm_suppression_max_age_seconds" {
  description = "Failsafe — force-enable alarm actions if deploy lasts longer than this."
  type        = number
  default     = 2700
}

# Approval gate
variable "approval_shared_secret" {
  type      = string
  sensitive = true
}

variable "approval_timeout_seconds" {
  type    = number
  default = 3600
}

# Subscribers
variable "alert_email_subscribers" {
  type    = list(string)
  default = []
}


# GitHub
variable "github_pat_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the GitHub PAT (Contents:Write on the deployment repo)."
  type        = string
}

variable "github_owner" {
  type    = string
  default = "soumajit131292"
}

variable "github_repo" {
  type    = string
  default = "aws-infra"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_values_path" {
  type    = string
  default = "helm-charts/helm/accesshub/values-prod-dr.yaml"
}

# Private DNS — record names (must match what's in route53-accesshub tfvars)
variable "rds_active_record_name" {
  type    = string
  default = "db.accesshub.internal"
}

variable "rds_dr_record_name" {
  type    = string
  default = "db-dr.accesshub.internal"
}

variable "record_ttl" {
  type    = number
  default = 60
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "prod-dr"
    Project     = "crave"
    ManagedBy   = "terraform"
    Component   = "dr-failover-orchestration"
  }
}
