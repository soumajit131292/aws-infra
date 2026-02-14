variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Kubernetes namespace where Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "chart_path" {
  description = "Path to local Argo CD Helm chart; leave empty to use module bundled chart"
  type        = string
  default     = ""
}

variable "create_namespace" {
  description = "Create the Argo CD namespace if it does not exist"
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
  default     = true
}

variable "values_files" {
  description = "List of paths to values files that will be loaded with file()"
  type        = list(string)
  default     = []
}

variable "values" {
  description = "List of raw YAML values to pass to the Argo CD chart"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Additional Helm set values"
  type        = map(string)
  default     = {}
}

variable "redis_auth_secret_name" {
  description = "Name of Redis auth secret expected by Argo CD chart"
  type        = string
  default     = "argocd-redis"
}
