variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "namespace" {
  description = "Namespace for the Wazuh agent."
  type        = string
  default     = "wazuh"
}

variable "release_name" {
  description = "Helm release name for the Wazuh agent."
  type        = string
  default     = "wazuh-agent"
}

variable "agent_group" {
  description = "Wazuh agent group (must match agent_cleanup_group in security/wazuh)."
  type        = string
  default     = "eks-prod"
}

variable "image_registry" {
  description = "Image registry for the Wazuh agent."
  type        = string
  default     = "495711089104.dkr.ecr.eu-west-1.amazonaws.com"
}

variable "image_repository" {
  description = "Image repository for the Wazuh agent."
  type        = string
  default     = "thirdparty/wazuh-agent"
}

variable "image_tag" {
  description = "Image tag for the Wazuh agent."
  type        = string
  default     = "4.14.10-amd64-platform"
}

variable "container_log_namespaces" {
  description = "Namespaces whose pod logs are shipped to Wazuh."
  type        = list(string)
  default     = []
}

variable "enable_journald" {
  description = "Collect node journald sshd and sudo events."
  type        = bool
  default     = false
}
