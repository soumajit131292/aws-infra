data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/prod/eu-west-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_subnets" "alb_public" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.vpc.outputs.vpc_id]
  }

  tags = {
    "kubernetes.io/role/elb"                                                        = "1"
    "kubernetes.io/cluster/${data.terraform_remote_state.eks.outputs.cluster_name}" = "shared"
  }
}
