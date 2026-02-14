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
