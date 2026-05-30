variable "region" {
  description = "AWS region for the WAF Web ACL (REGIONAL scope)."
  type        = string
  default     = "eu-central-1"
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

variable "waf_log_group_arn" {
  description = "CloudWatch log group ARN used by WAF logging."
  type        = string
}

variable "alb_resource_arn" {
  description = "ALB ARN for WAF association."
  type        = string
  default     = ""
}

variable "manage_alb_association" {
  description = "Set true to let Terraform manage WAF-ALB association. Keep false when Helm/Ingress annotation manages it."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the Web ACL resource."
  type        = map(string)
  default     = {}
}
