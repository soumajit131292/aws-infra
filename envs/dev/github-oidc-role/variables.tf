variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "allowed_branches" {
  description = "Branches allowed to assume the IAM role"
  type        = list(string)
  default     = ["main"]
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

