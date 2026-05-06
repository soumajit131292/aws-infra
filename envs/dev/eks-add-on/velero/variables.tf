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

variable "create_velero_kms_key" {
  description = "Create a customer-managed KMS key for Velero backup bucket encryption."
  type        = bool
  default     = true
}

variable "velero_kms_key_alias" {
  description = "Alias for Velero KMS key (without alias/ prefix)."
  type        = string
  default     = "dev-velero-backups"
}

variable "backup_bucket_retention_days" {
  description = "S3 lifecycle expiration in days for Velero backup objects."
  type        = number
  default     = 30
}

variable "backup_bucket_noncurrent_retention_days" {
  description = "S3 lifecycle expiration in days for noncurrent object versions."
  type        = number
  default     = 30
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

variable "kubectl_image_repository" {
  description = "Kubectl image repository used by Velero upgrade/cleanup CRD jobs."
  type        = string
  default     = "docker.io/bitnami/kubectl"
}

variable "kubectl_image_tag" {
  description = "Kubectl image tag used by Velero upgrade/cleanup CRD jobs."
  type        = string
  default     = "latest"
}

variable "enable_default_backup_schedule" {
  description = "Create a default Velero backup schedule."
  type        = bool
  default     = true
}

variable "backup_schedule_cron" {
  description = "Cron expression for default Velero schedule."
  type        = string
  default     = "0 2 * * *"
}

variable "backup_schedule_ttl_hours" {
  description = "TTL in hours for backups created by the default schedule."
  type        = number
  default     = 720
}
