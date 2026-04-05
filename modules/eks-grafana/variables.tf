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

variable "grafana_extra_values" {
  description = "Additional values yaml snippets for Grafana."
  type        = list(string)
  default     = []
}
