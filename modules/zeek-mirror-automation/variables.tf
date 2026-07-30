variable "name" {
  description = "Name prefix for the Lambda, IAM role, and EventBridge rules."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name whose worker nodes should be mirrored (matches the eks:cluster-name tag)."
  type        = string
}

variable "mirror_target_id" {
  description = "Traffic mirror target ID (the Zeek sensor ENI target)."
  type        = string
}

variable "mirror_filter_id" {
  description = "Traffic mirror filter ID to apply to each session."
  type        = string
}

variable "vni" {
  description = "VXLAN network identifier used for the mirror sessions."
  type        = number
  default     = 4789
}

variable "sweep_schedule" {
  description = "EventBridge schedule expression for the periodic reconcile sweep."
  type        = string
  default     = "rate(1 hour)"
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the Lambda."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
