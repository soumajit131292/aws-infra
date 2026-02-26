module "github_runners" {
  source = "../../../modules/github-runners"

  cluster_name      = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint  = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca        = data.terraform_remote_state.eks.outputs.cluster_ca_certificate
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer       = data.terraform_remote_state.eks.outputs.oidc_issuer_url

  aws_region = var.region

  github_org             = var.github_org
  github_app_id          = var.github_app_id
  github_installation_id = var.github_installation_id
  github_private_key     = var.github_private_key
  runner_max_replicas    = var.runner_max_replicas

  arc_controller_image_repository     = var.arc_controller_image_repository
  arc_controller_image_tag            = var.arc_controller_image_tag
  runner_image_repository             = var.runner_image_repository
  runner_image_tag                    = var.runner_image_tag
  kube_rbac_proxy_image_repository    = var.kube_rbac_proxy_image_repository
  kube_rbac_proxy_image_tag           = var.kube_rbac_proxy_image_tag
  cluster_autoscaler_image_repository = var.cluster_autoscaler_image_repository
  cluster_autoscaler_image_tag        = var.cluster_autoscaler_image_tag
}
