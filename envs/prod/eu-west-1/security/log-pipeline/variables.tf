variable "region" {
  description = "AWS region."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resource names."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the security log archive."
  type        = string
}

variable "kms_key_alias" {
  description = "KMS alias for the security-logs CMK."
  type        = string
}

variable "include_namespaces" {
  description = <<-EOT
    Kubernetes namespaces to include when shipping `application` (pod) logs.
    Subscription filter is built as: { ($.kubernetes.namespace_name = "ns1") || ($.kubernetes.namespace_name = "ns2") }
    Empty list = no namespace filter (ship everything).
  EOT
  type        = list(string)
  default     = ["accesshub"]
}

variable "ship_application" {
  description = "Subscription filter for /aws/containerinsights/<cluster>/application (pod stdout/stderr)."
  type        = bool
  default     = true
}

variable "ship_audit" {
  description = "Subscription filter for the EKS control plane audit events (in /aws/eks/<cluster>/cluster)."
  type        = bool
  default     = true
}

variable "ship_host" {
  description = "Subscription filter for /aws/containerinsights/<cluster>/host."
  type        = bool
  default     = false
}

variable "ship_dataplane" {
  description = "Subscription filter for /aws/containerinsights/<cluster>/dataplane."
  type        = bool
  default     = false
}

variable "ingress_log_group_name" {
  description = "Optional CloudWatch log group for ingress logs (e.g., ingress-nginx). Empty disables."
  type        = string
  default     = ""
}

variable "firehose_buffer_size_mb" {
  type    = number
  default = 128
}

variable "firehose_buffer_interval_seconds" {
  type    = number
  default = 300
}

variable "firehose_compression_format" {
  type    = string
  default = "GZIP"
}

variable "lifecycle_ia_days" {
  type    = number
  default = 30
}

variable "lifecycle_glacier_days" {
  type    = number
  default = 90
}

variable "lifecycle_deep_archive_days" {
  type    = number
  default = 180
}

variable "lifecycle_expiration_days" {
  type    = number
  default = 2555
}

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock. IRREVERSIBLE once true."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
