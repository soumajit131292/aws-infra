variable "name_prefix" {
  description = "Prefix for resource names (e.g., 'prod-dr-failover')."
  type        = string
}

variable "source_region" {
  description = "Primary AWS region (where prod runs)."
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "DR AWS region (where this orchestration runs)."
  type        = string
  default     = "eu-central-1"
}

###############################
# Aurora
###############################
variable "global_cluster_id" {
  description = "Aurora Global Cluster identifier (e.g., prod-accesshub-global)."
  type        = string
}

variable "dr_cluster_arn" {
  description = "ARN of the prod-dr Aurora cluster (member of the global cluster)."
  type        = string
}

###############################
# EFS
###############################
variable "source_efs_id" {
  description = "EFS file system ID in source region (replication source)."
  type        = string
}

variable "dr_efs_id" {
  description = "EFS file system ID in DR region (replication destination)."
  type        = string
}

###############################
# EKS
###############################
variable "dr_eks_cluster_name" {
  description = "Prod-DR EKS cluster name."
  type        = string
}

variable "dr_eks_nodegroup_name" {
  description = "Prod-DR EKS managed node group to scale on failover."
  type        = string
}

variable "target_node_desired" {
  description = "Desired node count to scale to during failover."
  type        = number
  default     = 3
}

variable "target_node_max" {
  description = "Maximum node count (must be >= target_node_desired)."
  type        = number
  default     = 5
}

variable "target_app_replicas" {
  description = "Target app replica count to commit to values-prod-dr.yaml."
  type        = number
  default     = 3
}

###############################
# Route 53 — public + private
###############################
variable "dr_private_hosted_zone_id" {
  description = "Prod-DR private hosted zone ID (the one storing rds_active CNAME)."
  type        = string
}

variable "rds_active_record_name" {
  description = "The app-facing DB CNAME (e.g., db.accesshub.internal)."
  type        = string
}

variable "rds_dr_record_name" {
  description = "The DR sub-record (e.g., db-dr.accesshub.internal) the active record gets flipped to."
  type        = string
}

variable "record_ttl" {
  description = "TTL on the rds_active CNAME flip."
  type        = number
  default     = 60
}

variable "public_health_check_url" {
  description = "Full URL hit by post-failover validation (e.g., https://prod-aws.accesshub-identity.com/health)."
  type        = string
}

variable "public_health_check_endpoint" {
  description = "FQDN to attach the Route 53 health check to (the public ALB hostname)."
  type        = string
}

variable "r53_dr_health_check_id" {
  description = "Optional: existing Route 53 health check ID for the prod-dr ALB to validate post-failover. Leave empty to skip."
  type        = string
  default     = ""
}

variable "cw_alarm_evaluation_periods" {
  description = "Phase 1 tuning: total window for the Route 53 alarm (eval N periods)."
  type        = number
  default     = 5
}

variable "cw_alarm_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N — alarm fires only if at least this many periods within the eval window breach. Should be < cw_alarm_evaluation_periods."
  type        = number
  default     = 3
}

variable "cw_alarm_period_seconds" {
  description = "CloudWatch alarm period in seconds."
  type        = number
  default     = 60
}

###############################
# GitHub (for replica scale via GitOps)
###############################
variable "github_pat_secret_arn" {
  description = "Secrets Manager secret ARN holding a GitHub PAT with Contents:Write on the deployment repo."
  type        = string
}

variable "github_owner" {
  description = "GitHub owner / org of the deployment repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name."
  type        = string
}

variable "github_branch" {
  description = "Branch the Lambda commits to."
  type        = string
  default     = "main"
}

variable "github_values_path" {
  description = "Path within the repo to the values-prod-dr.yaml file."
  type        = string
  default     = "helm-charts/helm/accesshub/values-prod-dr.yaml"
}

###############################
# Tier 1 alarm inputs — ALB
###############################
variable "prod_alb_name" {
  description = "Name of the prod ALB (used to look up arn_suffix via data source). Set to the same value as alb.ingress.kubernetes.io/load-balancer-name annotation."
  type        = string
}

variable "alb_5xx_threshold" {
  description = "Number of 5xx responses from ALB targets per 60s period before counting toward alarm."
  type        = number
  default     = 50
}

variable "alb_5xx_evaluation_periods" {
  description = "Phase 1 tuning: total window over which alb_5xx_threshold is evaluated."
  type        = number
  default     = 10
}

variable "alb_5xx_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for ALB 5xx alarm."
  type        = number
  default     = 5
}

variable "alb_unhealthy_period_seconds" {
  description = "CloudWatch alarm period for ALB UnHealthyHostCount."
  type        = number
  default     = 60
}

variable "alb_unhealthy_evaluation_periods" {
  description = "Phase 1 tuning: total window for ALB UnHealthyHostCount."
  type        = number
  default     = 10
}

variable "alb_unhealthy_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for ALB UnHealthyHostCount."
  type        = number
  default     = 7
}

###############################
# Tier 1 alarm inputs — Aurora
###############################
variable "prod_cluster_identifier" {
  description = "Aurora cluster identifier in the source region (e.g., prod-aurora-postgres)."
  type        = string
}

variable "dr_cluster_identifier" {
  description = "Aurora cluster identifier in the DR region (e.g., prod-dr-aurora-postgres)."
  type        = string
}

variable "aurora_replication_lag_threshold_ms" {
  description = "Alarm if Aurora Global Database replication lag exceeds this many milliseconds."
  type        = number
  default     = 60000 # 60 seconds
}

variable "aurora_replication_lag_evaluation_periods" {
  description = "Phase 1 tuning: total window for replication lag alarm."
  type        = number
  default     = 5
}

variable "aurora_replication_lag_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for replication lag alarm."
  type        = number
  default     = 3
}

variable "aurora_min_connections" {
  description = "Alarm if prod cluster DatabaseConnections drops below this for sustained period. Set to 0 to disable."
  type        = number
  default     = 1
}

variable "aurora_no_connections_evaluation_periods" {
  description = "Phase 1 tuning: total window for Aurora no-connections alarm."
  type        = number
  default     = 10
}

variable "aurora_no_connections_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for Aurora no-connections alarm."
  type        = number
  default     = 7
}

variable "aurora_db_load_threshold" {
  description = "Alarm threshold for Aurora DBLoad (average active sessions). Tune to instance class capacity."
  type        = number
  default     = 4
}

variable "aurora_db_load_evaluation_periods" {
  description = "Phase 1 tuning: total window for Aurora DBLoad alarm."
  type        = number
  default     = 10
}

variable "aurora_db_load_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for Aurora DBLoad alarm."
  type        = number
  default     = 7
}

###############################
# Tier 1 alarm inputs — EFS
###############################
variable "efs_replication_lag_threshold_sec" {
  description = "Alarm if EFS TimeSinceLastSync on the destination exceeds this many seconds."
  type        = number
  default     = 300 # 5 minutes
}

variable "efs_replication_lag_evaluation_periods" {
  description = "Phase 1 tuning: total window for EFS replication lag alarm."
  type        = number
  default     = 5
}

variable "efs_replication_lag_datapoints_to_alarm" {
  description = "Phase 1 tuning: M of N for EFS replication lag alarm."
  type        = number
  default     = 3
}

###############################
# Phase 2: alarm suppression
###############################
variable "argocd_webhook_secret" {
  description = "HMAC shared secret. ArgoCD Notifications uses this to sign webhook payloads; the Lambda verifies the signature. Leave empty to disable signature checks."
  type        = string
  sensitive   = true
  default     = ""
}

variable "alarm_suppression_max_age_seconds" {
  description = "If an ArgoCD deploy doesn't report 'deployed' within this many seconds after 'sync-started', the failsafe force-enables alarm actions. Should comfortably exceed your longest deploy time."
  type        = number
  default     = 2700 # 45 min
}

###############################
# Approval gate
###############################
variable "approval_shared_secret" {
  description = "Random shared-secret value required as ?sig= on the approval URL. Leave empty to disable signature check."
  type        = string
  sensitive   = true
  default     = ""
}

variable "approval_timeout_seconds" {
  description = "Step Functions waits this long for approval before failing."
  type        = number
  default     = 3600
}

###############################
# Notification subscribers
###############################
variable "alert_email_subscribers" {
  description = "Email addresses for alert/approval/completion notifications."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
