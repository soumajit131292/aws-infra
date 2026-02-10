data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "my-tf-states"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-tf-states"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}


module "alb_controller" {
  source = "../modules/eks-alb-controller"

  cluster_name      = data.terraform_remote_state.eks.outputs.cluster_name
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer_url   = data.terraform_remote_state.eks.outputs.oidc_issuer_url
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  region            = var.region
}

