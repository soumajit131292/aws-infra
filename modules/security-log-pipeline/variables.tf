variable "name_prefix" {
  description = "Prefix used in resource names (e.g., 'prod')."
  type        = string
}

variable "region" {
  description = "AWS region where Firehose, S3, KMS, and the subscribed CW log groups live."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the security log archive."
  type        = string
}

variable "kms_key_alias" {
  description = "KMS alias for the security-logs CMK (e.g., alias/<prefix>-security-logs)."
  type        = string
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window."
  type        = number
  default     = 30
}

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock on the bucket. IRREVERSIBLE once set."
  type        = bool
  default     = false
}

variable "lifecycle_ia_days" {
  description = "Transition to STANDARD_IA after N days."
  type        = number
  default     = 30
}

variable "lifecycle_glacier_days" {
  description = "Transition to GLACIER after N days."
  type        = number
  default     = 90
}

variable "lifecycle_deep_archive_days" {
  description = "Transition to DEEP_ARCHIVE after N days."
  type        = number
  default     = 180
}

variable "lifecycle_expiration_days" {
  description = "Expire objects after N days. Set 0 to disable expiration."
  type        = number
  default     = 2555
}

variable "firehose_buffer_size_mb" {
  description = "Firehose S3 buffer size in MB (1-128)."
  type        = number
  default     = 128
}

variable "firehose_buffer_interval_seconds" {
  description = "Firehose S3 buffer interval in seconds (0-900)."
  type        = number
  default     = 300
}

variable "firehose_compression_format" {
  description = "Firehose S3 compression format (UNCOMPRESSED, GZIP, ZIP, Snappy, HADOOP_SNAPPY)."
  type        = string
  default     = "GZIP"
}

variable "firehose_error_log_retention_days" {
  description = "Retention for the Firehose error CW log groups."
  type        = number
  default     = 30
}

variable "log_subscriptions" {
  description = <<-EOT
    Map of CloudWatch Logs subscriptions. Each entry creates:
      - one Firehose delivery stream landing in S3 under `s3_prefix`
      - one subscription filter on `log_group_name` that ships into that stream

    Keys must be DNS-safe (lowercase, hyphens). Used in Firehose stream names.
  EOT
  type = map(object({
    log_group_name = string
    s3_prefix      = string
    filter_pattern = optional(string, "")
  }))
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
