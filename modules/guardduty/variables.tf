variable "finding_publishing_frequency" {
  description = "How often GuardDuty exports findings to CloudWatch Events / SecurityHub (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)."
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be one of FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

variable "enable_eks_audit_logs" {
  description = "Enable GuardDuty EKS Protection (Kubernetes audit-log analysis)."
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Enable GuardDuty Runtime Monitoring (in-cluster agent). Priced per node vCPU/month -- keep off in dev to avoid the standing cost."
  type        = bool
  default     = false
}

variable "enable_eks_addon_management" {
  description = "Let GuardDuty auto-manage the aws-guardduty-agent EKS add-on. Only takes effect when enable_runtime_monitoring is true."
  type        = bool
  default     = true
}

variable "enable_rds_login_events" {
  description = "Enable GuardDuty RDS Protection (Aurora/RDS login anomaly + brute-force detection)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
