
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
    key    = "network/qa/eu-west-1/vpc/terraform.tfstate"
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

  core_node_instance_types        = var.core_node_instance_types
  core_node_max_pods              = 110
  enable_prefix_delegation        = true
  warm_prefix_target              = 1
  enable_cloudwatch_observability = true
  cluster_log_retention_in_days   = var.cluster_log_retention_in_days
  enable_metrics_server_addon     = var.enable_metrics_server_addon
  metrics_server_addon_version    = var.metrics_server_addon_version
  enable_efs_backup               = var.enable_efs_backup
  create_efs_logs_file_system     = var.create_efs_logs_file_system
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

#############################################
# Cluster-admin for the QA jumphost
#
# The QA API endpoint is private, so kubectl/helm/Terraform add-on runs go
# through the QA jumphost (envs/qa/eu-west-1/ubuntu-jumphost-vm). It uses the
# QA VPC's EC2 SSM role. QA-only: nothing here grants access to prod.
#############################################
resource "aws_eks_access_entry" "qa_jumphost" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.terraform_remote_state.vpc.outputs.ec2_ssm_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "qa_jumphost" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.qa_jumphost.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

#############################################
# IAM: let the QA jumphost role describe the QA cluster
#
# The access entry above grants Kubernetes RBAC, but `aws eks
# update-kubeconfig` first calls eks:DescribeCluster (an IAM action), and the
# QA SSM role only carries AmazonSSMManagedInstanceCore. Scoped to the QA
# cluster ARN only — it grants nothing on prod or any other cluster.
#############################################
data "aws_caller_identity" "current" {}

locals {
  qa_jumphost_role_name = element(split("/", data.terraform_remote_state.vpc.outputs.ec2_ssm_role_arn), length(split("/", data.terraform_remote_state.vpc.outputs.ec2_ssm_role_arn)) - 1)
  qa_cluster_arn        = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
}

resource "aws_iam_role_policy" "qa_jumphost_eks_describe" {
  name = "${module.eks.cluster_name}-jumphost-eks-describe"
  role = local.qa_jumphost_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DescribeQaCluster"
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = local.qa_cluster_arn
    }]
  })
}
