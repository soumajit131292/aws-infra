
#############################################
# AWS Provider
#############################################
provider "aws" {
  region = var.region
}

#############################################
# Read VPC + subnet details from remote state
#############################################
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

#############################################
# EKS module (creates the cluster)
#############################################
module "eks" {
  source = "../../../modules/eks"

  cluster_name      = var.cluster_name
  region            = var.region
  private_app_sg_id = data.terraform_remote_state.vpc.outputs.private_app_sg_id

  core_node_max_pods       = 110
  enable_prefix_delegation = true
  warm_prefix_target       = 1

  vpc_id                 = data.terraform_remote_state.vpc.outputs.vpc_id
  private_app_subnet_ids = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids

  tags = var.tags
}
