variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "create_alb_access_logs_bucket" {
  description = "Create S3 bucket and policy for ALB access logs"
  type        = bool
  default     = true
}

variable "alb_access_logs_bucket_force_destroy" {
  description = "If true, Terraform deletes all objects/versions in the ALB access logs bucket during destroy"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket_name" {
  description = "Existing S3 bucket name for ALB logs. Leave empty to auto-generate from prefix/account/region"
  type        = string
  default     = ""
}

variable "alb_access_logs_bucket_name_prefix" {
  description = "Prefix used when auto-generating ALB access logs bucket name"
  type        = string
  default     = "prod-accesshub-alb-access-logs"
}

variable "alb_access_logs_prefix" {
  description = "S3 key prefix for ALB access logs"
  type        = string
  default     = "alb/accesshub"
}

variable "alb_access_logs_retention_days" {
  description = "S3 lifecycle expiration in days for ALB access log objects"
  type        = number
  default     = 90
}

variable "alb_access_logs_noncurrent_retention_days" {
  description = "S3 lifecycle expiration in days for noncurrent ALB access log object versions"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for S3 resources"
  type        = map(string)
  default = {
    component = "alb-controller"
    env       = "prod"
  }
}
