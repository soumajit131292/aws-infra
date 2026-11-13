variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Namespace where Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "chart_path" {
  description = "Path to local Argo CD chart. Leave empty to use bundled module chart"
  type        = string
  default     = ""
}

variable "create_namespace" {
  description = "Create Argo CD namespace"
  type        = bool
  default     = true
}

variable "timeout" {
  description = "Helm operation timeout in seconds"
  type        = number
  default     = 600
}

variable "atomic" {
  description = "If true, uninstall release on failure"
  type        = bool
  default     = false
}

variable "values_files" {
  description = "Additional values files"
  type        = list(string)
  default     = []
}

variable "values" {
  description = "Inline values yaml snippets"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Additional Helm set values"
  type        = map(string)
  default     = {}
}

variable "manage_namespace" {
  description = "Whether Terraform should explicitly manage the namespace resource"
  type        = bool
  default     = false
}

variable "waf_acl_arn" {
  description = "Optional QA WAFv2 web ACL ARN for the Argo CD ALB. Empty = no WAF."
  type        = string
  default     = ""
}

variable "inbound_cidrs" {
  description = "CIDRs allowed to reach the Argo CD ALB (alb.ingress.kubernetes.io/inbound-cidrs). The ALB is internet-facing on HTTP with no WAF in QA, so keep this to office/VPN ranges."
  type        = list(string)

  validation {
    condition     = length(var.inbound_cidrs) > 0 && !contains(var.inbound_cidrs, "0.0.0.0/0") && alltrue([for c in var.inbound_cidrs : can(cidrhost(c, 0))])
    error_message = "Set inbound_cidrs in terraform.tfvars to your office/VPN CIDRs (valid CIDRs, not 0.0.0.0/0)."
  }
}
