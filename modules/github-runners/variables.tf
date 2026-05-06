variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cluster_ca" {}
variable "oidc_provider_arn" {}
variable "oidc_issuer" {}

variable "aws_region" {}

variable "github_org" {}
variable "github_app_id" {}
variable "github_installation_id" {}
variable "github_private_key" {
  sensitive = true
}

variable "runner_max_replicas" {
  default = 3
}

variable "arc_controller_image_repository" {
  type    = string
  default = "summerwind/actions-runner-controller"
}

variable "arc_controller_image_tag" {
  type    = string
  default = "v0.27.6"
}

variable "runner_image_repository" {
  type    = string
  default = "summerwind/actions-runner"
}

variable "runner_image_tag" {
  type    = string
  default = "latest"
}

variable "kube_rbac_proxy_image_repository" {
  type    = string
  default = "quay.io/brancz/kube-rbac-proxy"
}

variable "kube_rbac_proxy_image_tag" {
  type    = string
  default = "v0.13.1"
}

variable "cluster_autoscaler_image_repository" {
  type    = string
  default = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_image_tag" {
  type    = string
  default = "v1.31.0"
}

variable "controller_node_selector" {
  description = "Node selector for ARC controller and cluster-autoscaler pods."
  type        = map(string)
  default = {
    role = "core"
  }
}

variable "runner_node_selector" {
  description = "Node selector for self-hosted runner pods."
  type        = map(string)
  default = {
    role = "github-runners-spot"
  }
}

variable "runner_taint_key" {
  description = "Taint key tolerated by runner pods."
  type        = string
  default     = "workload"
}

variable "runner_taint_value" {
  description = "Taint value tolerated by runner pods."
  type        = string
  default     = "github-runners"
}
