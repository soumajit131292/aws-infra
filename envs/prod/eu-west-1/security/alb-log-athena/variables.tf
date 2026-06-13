variable "region" {
  description = "AWS region."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resource names."
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

variable "athena_workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "athena_results_prefix" {
  description = "Prefix in the central security log bucket for Athena query results."
  type        = string
}

variable "projection_start_date" {
  description = "First ALB log date for partition projection, formatted yyyy/MM/dd."
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
  type    = map(string)
  default = {}
}
