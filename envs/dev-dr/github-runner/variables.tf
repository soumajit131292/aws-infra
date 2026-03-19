variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "github_org" {
  description = "GitHub organization where runners should register"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID used by ARC"
  type        = string
}

variable "github_installation_id" {
  description = "GitHub App Installation ID used by ARC"
  type        = string
}

variable "github_private_key" {
  description = "GitHub App private key PEM content"
  type        = string
  sensitive   = true
}

variable "runner_max_replicas" {
  description = "Maximum ARC runner replicas"
  type        = number
  default     = 3
}

variable "arc_controller_image_repository" {
  description = "ARC controller image repository"
  type        = string
  default     = "summerwind/actions-runner-controller"
}

variable "arc_controller_image_tag" {
  description = "ARC controller image tag"
  type        = string
  default     = "v0.27.6"
}

variable "runner_image_repository" {
  description = "GitHub runner image repository"
  type        = string
  default     = "summerwind/actions-runner"
}

variable "runner_image_tag" {
  description = "GitHub runner image tag"
  type        = string
  default     = "latest"
}

variable "kube_rbac_proxy_image_repository" {
  description = "kube-rbac-proxy image repository"
  type        = string
  default     = "quay.io/brancz/kube-rbac-proxy"
}

variable "kube_rbac_proxy_image_tag" {
  description = "kube-rbac-proxy image tag"
  type        = string
  default     = "v0.13.1"
}

variable "cluster_autoscaler_image_repository" {
  description = "Cluster autoscaler image repository"
  type        = string
  default     = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_image_tag" {
  description = "Cluster autoscaler image tag"
  type        = string
  default     = "v1.31.0"
}
