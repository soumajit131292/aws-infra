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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "DB subnet IDs used by DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to Aurora on 5432"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to Aurora on 5432"
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

  validation {
    condition     = var.backup_retention_period >= 7 && var.backup_retention_period <= 30
    error_message = "backup_retention_period must be between 7 and 30 days."
  }
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

variable "performance_insights_enabled" {
  description = "Enable Performance Insights on instances"
  type        = bool
  default     = true
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds. Use 0 to disable."
  type        = number
  default     = 0
}

variable "enhanced_monitoring_role_arn" {
  description = "Optional existing IAM role ARN for RDS Enhanced Monitoring. If empty and interval > 0, module creates one."
  type        = string
  default     = ""
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrades for instances"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to Aurora resources"
  type        = map(string)
  default     = {}
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy in front of Aurora cluster."
  type        = bool
  default     = false
}

variable "rds_proxy_name" {
  description = "Optional RDS Proxy name. If empty, <cluster_identifier>-proxy is used."
  type        = string
  default     = ""
}

variable "rds_proxy_secret_arn" {
  description = "Secrets Manager secret ARN used by RDS Proxy for DB authentication."
  type        = string
  default     = ""
}

variable "rds_proxy_subnet_ids" {
  description = "Subnet IDs for RDS Proxy endpoints. If empty, db_subnet_ids are used."
  type        = list(string)
  default     = []
}

variable "rds_proxy_iam_auth" {
  description = "RDS Proxy IAM auth mode: REQUIRED or DISABLED."
  type        = string
  default     = "DISABLED"
}

variable "rds_proxy_require_tls" {
  description = "Require TLS for connections to RDS Proxy."
  type        = bool
  default     = true
}

variable "rds_proxy_idle_client_timeout" {
  description = "Idle client timeout (seconds) for RDS Proxy."
  type        = number
  default     = 1800
}

variable "rds_proxy_debug_logging" {
  description = "Enable RDS Proxy debug logging."
  type        = bool
  default     = false
}

variable "rds_proxy_max_connections_percent" {
  description = "Maximum DB connections percent for RDS Proxy target group."
  type        = number
  default     = 100
}

variable "rds_proxy_max_idle_connections_percent" {
  description = "Maximum idle DB connections percent for RDS Proxy target group."
  type        = number
  default     = 50
}

variable "rds_proxy_connection_borrow_timeout" {
  description = "Connection borrow timeout (seconds) for RDS Proxy target group."
  type        = number
  default     = 120
}

variable "enforce_rds_proxy_only" {
  description = "When true and RDS Proxy is enabled, allow DB ingress only from proxy security group."
  type        = bool
  default     = false
}
