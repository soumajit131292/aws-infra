module "alb_controller" {
  source = "../../../modules/eks-alb-controller"

  cluster_name       = data.terraform_remote_state.eks.outputs.cluster_name
  region             = var.region
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  oidc_provider_arn  = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer_url    = data.terraform_remote_state.eks.outputs.oidc_issuer_url

  tags = {
    component = "alb-controller"
  }
}
