
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
    key    = "network/prod-dr/eu-central-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

#############################################
# EKS module (creates the cluster)
#############################################
module "eks" {
  source = "../../../../modules/eks"

  cluster_name      = var.cluster_name
  region            = var.region
  private_app_sg_id = data.terraform_remote_state.vpc.outputs.private_app_sg_id

  core_node_max_pods              = 110
  enable_prefix_delegation        = true
  warm_prefix_target              = 1
  enable_cloudwatch_observability = true
  enable_metrics_server_addon     = var.enable_metrics_server_addon
  metrics_server_addon_version    = var.metrics_server_addon_version
  enable_efs_backup               = true
  create_efs_file_system          = false
  enable_spot_runner_node_group   = var.enable_spot_runner_node_group
  spot_runner_instance_types      = var.spot_runner_instance_types
  spot_runner_min_size            = var.spot_runner_min_size
  spot_runner_desired_size        = var.spot_runner_desired_size
  spot_runner_max_size            = var.spot_runner_max_size
  spot_runner_taint_key           = var.spot_runner_taint_key
  spot_runner_taint_value         = var.spot_runner_taint_value

  vpc_id                 = data.terraform_remote_state.vpc.outputs.vpc_id
  private_app_subnet_ids = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids

  tags = var.tags
}
