variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
