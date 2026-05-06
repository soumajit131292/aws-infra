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

variable "create_cluster_secret_store" {
  description = "Create a default ClusterSecretStore for AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "cluster_secret_store_name" {
  description = "Name of the default ClusterSecretStore"
  type        = string
  default     = "aws-secretsmanager"
}

variable "aws_region" {
  description = "AWS region used by the ClusterSecretStore provider"
  type        = string
  default     = "us-east-1"
}

variable "service_account_name" {
  description = "Service account name used by ESO for IRSA auth in ClusterSecretStore"
  type        = string
  default     = "external-secrets"
}
