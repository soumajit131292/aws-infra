variable "name_prefix" {
  description = "Prefix used in resource names."
  type        = string
}

variable "region" {
  description = "AWS region where the ALB logs live."
  type        = string
}

variable "account_id" {
  description = "AWS account ID that owns the ALB log bucket path."
  type        = string
}

variable "database_name" {
  description = "Glue/Athena database name."
  type        = string
}

variable "table_name" {
  description = "Glue/Athena table name for ALB access logs."
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "S3 bucket containing ALB access logs."
  type        = string
}

variable "alb_logs_prefix" {
  description = "S3 prefix before AWSLogs/<account-id>/elasticloadbalancing/<region>."
  type        = string
}

variable "projection_start_date" {
  description = "First date available for partition projection, formatted yyyy/MM/dd."
  type        = string
}

variable "athena_workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "athena_results_bucket_name" {
  description = "S3 bucket for Athena query results."
  type        = string
}

variable "athena_results_prefix" {
  description = "S3 prefix for Athena query results."
  type        = string
}

variable "athena_results_kms_key_arn" {
  description = "KMS key ARN used to encrypt Athena query results."
  type        = string
}

variable "bytes_scanned_cutoff_per_query" {
  description = "Maximum bytes Athena may scan per query in this workgroup."
  type        = number
  default     = 10737418240
}

variable "create_reader_policy" {
  description = "Create an IAM managed policy that can query these logs."
  type        = bool
  default     = true
}

variable "reader_policy_name" {
  description = "Name for the optional IAM managed policy."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
