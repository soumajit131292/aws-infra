variable "region" {
  description = "AWS region for the WAF Web ACL (REGIONAL scope)."
  type        = string
  default     = "eu-west-1"
}

variable "web_acl_name" {
  description = "Name of the QA WAF Web ACL."
  type        = string

  validation {
    condition     = can(regex("^qa-", var.web_acl_name))
    error_message = "QA web ACL name must start with qa- (never reuse the prod ACL name)."
  }
}

variable "scope" {
  description = "WAF scope. Use REGIONAL for ALB/API Gateway/AppSync."
  type        = string
  default     = "REGIONAL"
}

variable "tags" {
  description = "Tags to apply to the Web ACL resource."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "Retention (days) for the QA WAF log group."
  type        = number
  default     = 30
}
