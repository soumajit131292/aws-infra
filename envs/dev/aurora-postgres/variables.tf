variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_identifier" {
  description = "Aurora cluster identifier"
  type        = string
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master password for Aurora PostgreSQL"
  type        = string
  sensitive   = true
  default     = null
}

variable "db_credentials_secret_name" {
  description = "Optional Secrets Manager secret name containing JSON {\"username\":\"...\",\"password\":\"...\"}"
  type        = string
  default     = ""
}

variable "db_credentials_secret_version_stage" {
  description = "Secret version stage to read from Secrets Manager"
  type        = string
  default     = "AWSCURRENT"
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "allowed_cidr_blocks" {
  description = "Additional CIDRs allowed on 5432"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Aurora PostgreSQL port"
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Backup window in UTC"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Maintenance window in UTC"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on cluster deletion"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier when skip_final_snapshot is false"
  type        = string
  default     = ""
}

variable "apply_immediately" {
  description = "Apply modifications immediately"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption"
  type        = string
  default     = null
}

variable "create_rds_kms_key" {
  description = "Create a customer-managed KMS key for Aurora encryption."
  type        = bool
  default     = true
}

variable "rds_kms_key_alias" {
  description = "Alias for the Aurora KMS key (without alias/ prefix)."
  type        = string
  default     = "dev-aurora-postgres"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of logs to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "cloudwatch_log_retention_in_days" {
  description = "CloudWatch log retention (days) for Aurora PostgreSQL exported logs."
  type        = number
  default     = 7
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights on instances"
  type        = bool
  default     = true
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds. Use 0 to disable."
  type        = number
  default     = 60
}

variable "enhanced_monitoring_role_arn" {
  description = "Optional existing IAM role ARN for RDS Enhanced Monitoring."
  type        = string
  default     = ""
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrades for instances"
  type        = bool
  default     = true
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy in front of Aurora cluster."
  type        = bool
  default     = true
}

variable "rds_proxy_name" {
  description = "Optional RDS Proxy name."
  type        = string
  default     = ""
}

variable "rds_proxy_secret_arn" {
  description = "Optional explicit Secrets Manager ARN for RDS Proxy auth."
  type        = string
  default     = ""
}

variable "rds_proxy_subnet_ids" {
  description = "Optional explicit subnet IDs for RDS Proxy."
  type        = list(string)
  default     = []
}

variable "rds_proxy_iam_auth" {
  description = "RDS Proxy IAM auth mode: REQUIRED or DISABLED."
  type        = string
  default     = "DISABLED"
}

variable "enforce_rds_proxy_only" {
  description = "When true, DB SG allows ingress only from RDS Proxy SG."
  type        = bool
  default     = true
}

variable "rds_proxy_max_connections_percent" {
  description = "Maximum DB connections percent for RDS Proxy target group."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
