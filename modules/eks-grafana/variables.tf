variable "namespace" {
  description = "Namespace for Grafana add-on."
  type        = string
  default     = "monitoring"
}

variable "create_namespace" {
  description = "Whether to create namespace."
  type        = bool
  default     = true
}

variable "grafana_release_name" {
  description = "Helm release name for Grafana."
  type        = string
  default     = "grafana"
}

variable "grafana_chart_path" {
  description = "Path to local Grafana chart. If empty, use sibling downloaded chart."
  type        = string
  default     = ""
}

variable "grafana_image_registry" {
  description = "Image registry for Grafana."
  type        = string
  default     = "docker.io"
}

variable "grafana_image_repository" {
  description = "Image repository for Grafana."
  type        = string
  default     = "grafana/grafana"
}

variable "grafana_image_tag" {
  description = "Image tag for Grafana."
  type        = string
  default     = "12.3.1"
}

variable "init_chown_image_registry" {
  description = "Image registry for initChownData container."
  type        = string
  default     = "docker.io"
}

variable "init_chown_image_repository" {
  description = "Image repository for initChownData container."
  type        = string
  default     = "library/busybox"
}

variable "init_chown_image_tag" {
  description = "Image tag for initChownData container."
  type        = string
  default     = "1.31.1"
}

variable "cluster_name" {
  description = "EKS cluster name used to build default IAM role name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA condition keys."
  type        = string
}

variable "service_account_name" {
  description = "Grafana Kubernetes service account name."
  type        = string
  default     = "grafana"
}

variable "enable_irsa" {
  description = "Create IRSA role and annotate Grafana service account."
  type        = bool
  default     = true
}

variable "irsa_role_name" {
  description = "Optional custom IAM role name for Grafana IRSA."
  type        = string
  default     = ""
}

variable "enable_amp_datasource" {
  description = "Configure AMP datasource in Grafana values."
  type        = bool
  default     = true
}

variable "amp_workspace_arn" {
  description = "Amazon Managed Prometheus workspace ARN used by Grafana datasource and IAM policy."
  type        = string
  default     = ""
}

variable "amp_region" {
  description = "Region for AMP datasource endpoint and SigV4 auth."
  type        = string
  default     = "us-east-1"
}

variable "amp_datasource_name" {
  description = "Grafana datasource name for AMP."
  type        = string
  default     = "AMP"
}

variable "grafana_extra_values" {
  description = "Additional values yaml snippets for Grafana."
  type        = list(string)
  default     = []
}
