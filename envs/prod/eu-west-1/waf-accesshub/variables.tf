variable "region" {
  description = "AWS region for the WAF Web ACL (REGIONAL scope)."
  type        = string
  default     = "eu-west-1"
}

variable "web_acl_name" {
  description = "Name of the existing WAF Web ACL."
  type        = string
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
