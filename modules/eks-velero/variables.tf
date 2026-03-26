variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "velero"
}

variable "namespace" {
  description = "Namespace for Velero"
  type        = string
  default     = "velero"
}

variable "use_local_chart" {
  description = "Use local checked-in Velero chart instead of remote repository."
  type        = bool
  default     = true
}

variable "local_chart_path" {
  description = "Relative path (from module root) to the local Velero chart directory."
  type        = string
  default     = "velero"
}

variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://vmware-tanzu.github.io/helm-charts"
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "velero"
}

variable "chart_version" {
  description = "Velero Helm chart version"
  type        = string
  default     = "7.2.1"
}

variable "service_account_name" {
  description = "Kubernetes service account name for Velero server"
  type        = string
  default     = "velero"
}

variable "backup_bucket_name" {
  description = "S3 bucket used by Velero backups"
  type        = string
}

variable "aws_region" {
  description = "AWS region for backup and snapshot locations"
  type        = string
}

variable "aws_plugin_image" {
  description = "Velero AWS plugin image"
  type        = string
  default     = "velero/velero-plugin-for-aws:v1.10.0"
}

variable "velero_image_repository" {
  description = "Velero server image repository."
  type        = string
  default     = "velero/velero"
}

variable "velero_image_tag" {
  description = "Velero server image tag."
  type        = string
  default     = "v1.14.1"
}

variable "extra_values" {
  description = "Additional helm values snippets"
  type        = list(string)
  default     = []
}
