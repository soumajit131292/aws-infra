variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for Grafana add-on."
  type        = string
  default     = "monitoring"
}

variable "grafana_release_name" {
  description = "Helm release name for Grafana."
  type        = string
  default     = "grafana"
}

variable "grafana_chart_path" {
  description = "Path to local Grafana chart."
  type        = string
  default     = "../../../../modules/grafana/grafana"
}

variable "grafana_image_registry" {
  description = "Image registry for Grafana."
  type        = string
  default     = "495711089104.dkr.ecr.us-east-1.amazonaws.com"
}

variable "grafana_image_repository" {
  description = "Image repository for Grafana."
  type        = string
  default     = "thirdparty/grafana"
}

variable "grafana_image_tag" {
  description = "Image tag for Grafana."
  type        = string
  default     = "12.3.1-amd64-platform"
}

variable "init_chown_image_registry" {
  description = "Image registry for initChownData container."
  type        = string
  default     = "495711089104.dkr.ecr.us-east-1.amazonaws.com"
}

variable "init_chown_image_repository" {
  description = "Image repository for initChownData container."
  type        = string
  default     = "thirdparty/busybox"
}

variable "init_chown_image_tag" {
  description = "Image tag for initChownData container."
  type        = string
  default     = "1.31.1-amd64-platform"
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
  description = "Optional AMP workspace ARN override; if empty, it is read from managed-prometheus remote state."
  type        = string
  default     = ""
}

variable "amp_datasource_name" {
  description = "Grafana datasource name for AMP."
  type        = string
  default     = "AMP"
}
