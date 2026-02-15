variable "release_name" {
  description = "Helm release name for External Secrets"
  type        = string
  default     = "external-secrets"
}

variable "namespace" {
  description = "Kubernetes namespace where External Secrets will be installed"
  type        = string
  default     = "external-secrets"
}

variable "chart_path" {
  description = "Path to local External Secrets Helm chart; leave empty to use module bundled chart"
  type        = string
  default     = ""
}

variable "create_namespace" {
  description = "Create the External Secrets namespace if it does not exist"
  type        = bool
  default     = true
}

variable "manage_namespace" {
  description = "Whether Terraform should explicitly manage the namespace resource"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "Time in seconds to wait for Helm release operations"
  type        = number
  default     = 600
}

variable "atomic" {
  description = "If true, uninstall release on failure"
  type        = bool
  default     = false
}

variable "values_files" {
  description = "List of paths to values files that will be loaded with file()"
  type        = list(string)
  default     = []
}

variable "values" {
  description = "List of raw YAML values to pass to the External Secrets chart"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Additional Helm set values"
  type        = map(string)
  default     = {}
}
