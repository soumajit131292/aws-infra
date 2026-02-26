variable "region" {
  description = "AWS region where the ALB exists."
  type        = string
}

variable "hosted_zone_name" {
  description = "Public Route 53 hosted zone name (must end with a dot, e.g. example.com.)."
  type        = string
}

variable "record_name" {
  description = "FQDN to create (e.g. accesshub-dev.example.com)."
  type        = string
}

variable "alb_name" {
  description = "Application Load Balancer name created by ingress controller."
  type        = string
}

variable "evaluate_target_health" {
  description = "Evaluate ALB target health for the alias record."
  type        = bool
  default     = true
}
