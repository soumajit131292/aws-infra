variable "region" {
  description = "AWS region for the GuardDuty detector."
  type        = string
  default     = "eu-central-1"
}

variable "finding_publishing_frequency" {
  description = "GuardDuty finding export cadence."
  type        = string
  default     = "SIX_HOURS"
}

variable "enable_eks_audit_logs" {
  description = "Enable EKS Protection (Kubernetes audit logs)."
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Enable EKS Runtime Monitoring (per-vCPU cost driver)."
  type        = bool
  default     = true
}

variable "enable_eks_addon_management" {
  description = "Auto-manage the aws-guardduty-agent EKS add-on when runtime monitoring is on."
  type        = bool
  default     = true
}

variable "enable_rds_login_events" {
  description = "Enable RDS Protection for Aurora PostgreSQL login events."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
