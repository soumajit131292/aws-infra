variable "release_name" {
  description = "Helm release name for the Wazuh agent"
  type        = string
  default     = "wazuh-agent"
}

variable "namespace" {
  description = "Kubernetes namespace for the Wazuh agent DaemonSet"
  type        = string
  default     = "wazuh"
}

variable "chart_path" {
  description = "Path to local Wazuh agent Helm chart; leave empty to use the module bundled chart"
  type        = string
  default     = ""
}

variable "manager_address" {
  description = "Private IP or DNS of the Wazuh manager the agents report to"
  type        = string
}

variable "agent_group" {
  description = "Wazuh agent group assigned at enrollment (must exist on the manager)"
  type        = string
  default     = "eks-prod"
}

variable "cluster_name" {
  description = "EKS cluster name, attached to every agent as the 'cluster' label"
  type        = string
  default     = ""
}

variable "image_registry" {
  description = "Image registry for the Wazuh agent"
  type        = string
}

variable "image_repository" {
  description = "Image repository for the Wazuh agent"
  type        = string
  default     = "thirdparty/wazuh-agent"
}

variable "image_tag" {
  description = "Image tag for the Wazuh agent (must not be newer than the manager)"
  type        = string
}

variable "container_log_namespaces" {
  description = "Namespaces whose pod stdout/stderr logs are shipped to Wazuh (every event is indexed; keep it short)"
  type        = list(string)
  default     = []
}

variable "enable_journald" {
  description = "Collect node journald events matching the chart's journald filters (sshd and sudo by default)"
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

variable "values" {
  description = "Additional raw YAML values layered on top of the module values"
  type        = list(string)
  default     = []
}
