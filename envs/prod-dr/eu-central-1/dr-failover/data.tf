# Read state from upstream stacks rather than hardcoding ARNs/IDs.

# Prod Aurora cluster (for cluster_arn used in cross-region failover commands).
data "terraform_remote_state" "prod_aurora" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "database/prod/eu-west-1/aurora-postgres/terraform.tfstate"
    region = "us-east-1"
  }
}

# Prod-DR Aurora cluster (the secondary that will be promoted).
data "terraform_remote_state" "prod_dr_aurora" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "database/prod-dr/eu-central-1/aurora-postgres/terraform.tfstate"
    region = "us-east-1"
  }
}

# Aurora Global Cluster identifier.
data "terraform_remote_state" "aurora_global" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "aurora/prod/eu-west-1/global-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}

# Prod EKS (for source EFS ID, used by the EFS replication stack).
data "terraform_remote_state" "prod_eks" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

# Prod-DR EKS (for cluster name + nodegroup name).
data "terraform_remote_state" "prod_dr_eks" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod-dr/eu-central-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

# Prod-DR private hosted zone ID (the one apps in prod-dr query for db.accesshub.internal).
data "terraform_remote_state" "prod_dr_route53" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "dns/prod-dr/eu-central-1/route53-accesshub/terraform.tfstate"
    region = "us-east-1"
  }
}

# EFS Replication stack output: destination EFS ID in prod-dr.
data "terraform_remote_state" "efs_replication" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "efs/prod/eu-west-1/replication/terraform.tfstate"
    region = "us-east-1"
  }
}

# Shared secrets from Secrets Manager (eu-central-1 / default provider).
data "aws_secretsmanager_secret_version" "approval_shared_secret" {
  secret_id = var.approval_shared_secret_arn
}

data "aws_secretsmanager_secret_version" "argocd_webhook_secret" {
  secret_id = var.argocd_webhook_secret_arn
}
