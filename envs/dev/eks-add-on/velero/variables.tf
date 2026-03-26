variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for Velero"
  type        = string
  default     = "velero"
}

variable "helm_release_name" {
  description = "Helm release name"
  type        = string
  default     = "velero"
}

variable "use_local_chart" {
  description = "Use local checked-in Velero chart."
  type        = bool
  default     = true
}

variable "velero_chart_version" {
  description = "Velero Helm chart version"
  type        = string
  default     = "7.2.1"
}

variable "velero_service_account_name" {
  description = "Kubernetes service account name used by Velero"
  type        = string
  default     = "velero"
}

variable "create_backup_bucket" {
  description = "Create S3 backup bucket for Velero"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Existing S3 bucket name for Velero backups. If empty and create_backup_bucket=true, a name is generated."
  type        = string
  default     = ""
}

variable "backup_bucket_name_prefix" {
  description = "Bucket name prefix used when auto-generating backup bucket name"
  type        = string
  default     = "dev-eks-velero-backups"
}

variable "tags" {
  description = "Tags applied to Velero resources"
  type        = map(string)
  default = {
    component = "velero"
    env       = "dev"
  }
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

variable "velero_plugin_image" {
  description = "Velero AWS plugin image."
  type        = string
  default     = "velero/velero-plugin-for-aws:v1.10.0"
}
