variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "repository_prefix" {
  description = "Repository namespace for QA images (prod/dev use accesshub/)."
  type        = string
  default     = "accesshub-qa"

  validation {
    condition     = var.repository_prefix != "accesshub" && can(regex("qa", var.repository_prefix))
    error_message = "QA repositories must not share the prod/dev 'accesshub' namespace."
  }
}

variable "services" {
  description = "Service names; one repository each (matches the build workflows' matrix)."
  type        = list(string)
}

variable "keep_last_images" {
  description = "Images kept per repository; older ones expire."
  type        = number
  default     = 30
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repositories that still contain images."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
