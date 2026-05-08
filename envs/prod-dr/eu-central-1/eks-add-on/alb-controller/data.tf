data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/prod-dr/eu-central-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod-dr/eu-central-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
