variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for node monitoring add-ons."
  type        = string
  default     = "monitoring"
}

variable "kube_state_metrics_release_name" {
  description = "Helm release name for kube-state-metrics."
  type        = string
  default     = "kube-state-metrics"
}

variable "node_exporter_release_name" {
  description = "Helm release name for node-exporter."
  type        = string
  default     = "prometheus-node-exporter"
}

variable "kube_state_metrics_chart_path" {
  description = "Path to local kube-state-metrics chart."
  type        = string
  default     = "../../../../../modules/kube-state-metrics/kube-state-metrics"
}

variable "node_exporter_chart_path" {
  description = "Path to local node-exporter chart."
  type        = string
  default     = "../../../../../modules/node-exporter/prometheus-node-exporter"
}

variable "kube_state_metrics_image_registry" {
  description = "Image registry for kube-state-metrics."
  type        = string
  default     = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
}

variable "kube_state_metrics_image_repository" {
  description = "Image repository for kube-state-metrics."
  type        = string
  default     = "thirdparty/kube-state-metrics"
}

variable "kube_state_metrics_image_tag" {
  description = "Image tag for kube-state-metrics."
  type        = string
  default     = "v2.18.0-amd64-platform"
}

variable "node_exporter_image_registry" {
  description = "Image registry for node-exporter."
  type        = string
  default     = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
}

variable "node_exporter_image_repository" {
  description = "Image repository for node-exporter."
  type        = string
  default     = "thirdparty/node-exporter"
}

variable "node_exporter_image_tag" {
  description = "Image tag for node-exporter."
  type        = string
  default     = "v1.10.2-amd64-platform"
}
