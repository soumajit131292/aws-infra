variable "namespace" {
  description = "Namespace for node monitoring add-ons."
  type        = string
  default     = "monitoring"
}

variable "create_namespace" {
  description = "Whether to create namespace."
  type        = bool
  default     = true
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
  description = "Path to kube-state-metrics chart. If empty, use sibling downloaded chart."
  type        = string
  default     = ""
}

variable "node_exporter_chart_path" {
  description = "Path to node-exporter chart. If empty, use sibling downloaded chart."
  type        = string
  default     = ""
}

variable "kube_state_metrics_image_registry" {
  description = "Image registry for kube-state-metrics."
  type        = string
  default     = "registry.k8s.io"
}

variable "kube_state_metrics_image_repository" {
  description = "Image repository for kube-state-metrics."
  type        = string
  default     = "kube-state-metrics/kube-state-metrics"
}

variable "kube_state_metrics_image_tag" {
  description = "Image tag for kube-state-metrics."
  type        = string
  default     = "v2.18.0"
}

variable "node_exporter_image_registry" {
  description = "Image registry for node-exporter."
  type        = string
  default     = "quay.io"
}

variable "node_exporter_image_repository" {
  description = "Image repository for node-exporter."
  type        = string
  default     = "prometheus/node-exporter"
}

variable "node_exporter_image_tag" {
  description = "Image tag for node-exporter."
  type        = string
  default     = "v1.10.2"
}

variable "kube_state_metrics_extra_values" {
  description = "Additional values yaml snippets for kube-state-metrics."
  type        = list(string)
  default     = []
}

variable "node_exporter_extra_values" {
  description = "Additional values yaml snippets for node-exporter."
  type        = list(string)
  default     = []
}
