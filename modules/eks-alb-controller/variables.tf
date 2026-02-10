############################################
# Required inputs
############################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region where the EKS cluster is running"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "alb_iam_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller (created in EKS stack)"
  type        = string
}

############################################
# Optional / metadata
############################################

variable "tags" {
  description = "Tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
