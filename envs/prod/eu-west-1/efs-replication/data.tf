data "aws_caller_identity" "current" {}

# Source EFS lives on the prod EKS cluster
data "terraform_remote_state" "prod_eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

# Destination VPC + subnets + private app SG live in prod-dr
data "terraform_remote_state" "prod_dr_vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/prod-dr/eu-central-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Destination EKS cluster SG (needed for mount-target SG ingress)
data "terraform_remote_state" "prod_dr_eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod-dr/eu-central-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  source_efs_id = data.terraform_remote_state.prod_eks.outputs.efs_file_system_id

  dr_vpc_id                 = data.terraform_remote_state.prod_dr_vpc.outputs.vpc_id
  dr_private_app_subnet_ids = data.terraform_remote_state.prod_dr_vpc.outputs.private_app_subnet_ids
  dr_private_app_sg_id      = data.terraform_remote_state.prod_dr_vpc.outputs.private_app_sg_id
  dr_eks_cluster_sg_id      = data.terraform_remote_state.prod_dr_eks.outputs.cluster_security_group_id
}
