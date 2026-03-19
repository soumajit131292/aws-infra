variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "release_name" {
  description = "Helm release name for External Secrets"
  type        = string
  default     = "external-secrets"
}

variable "namespace" {
  description = "Namespace where External Secrets will be installed"
  type        = string
  default     = "external-secrets"
}

variable "chart_path" {
  description = "Path to local External Secrets chart. Leave empty to use bundled module chart"
  type        = string
  default     = ""
}

variable "create_namespace" {
  description = "Create External Secrets namespace"
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

variable "service_account_name" {
  description = "Kubernetes service account name used by External Secrets controller"
  type        = string
  default     = "external-secrets"
}

variable "irsa_role_name" {
  description = "Optional explicit IAM role name for ESO IRSA. If empty, a name will be derived from cluster name."
  type        = string
  default     = ""
}

variable "secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs that ESO can read"
  type        = list(string)
  default     = ["*"]
}

variable "kms_key_arns" {
  description = "Optional KMS key ARNs used to decrypt secrets. Leave empty to skip kms:Decrypt."
  type        = list(string)
  default     = []
}

variable "create_cluster_secret_store" {
  description = "Create a default ClusterSecretStore for AWS Secrets Manager"
  type        = bool
  default     = true
}

variable "cluster_secret_store_name" {
  description = "Name of the default ClusterSecretStore"
  type        = string
  default     = "aws-secretsmanager"
}
