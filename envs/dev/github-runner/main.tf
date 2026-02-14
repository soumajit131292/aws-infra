module "github_runners" {
  source = "../../modules/github-runners"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_ca        = module.eks.cluster_ca
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer

  private_subnet_ids = var.private_subnet_ids
  aws_region         = var.aws_region

  github_org             = "your-org"
  github_app_id          = var.github_app_id
  github_installation_id = var.github_installation_id
  github_private_key     = var.github_private_key
}
