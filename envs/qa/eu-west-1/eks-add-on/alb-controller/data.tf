data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/qa/eu-west-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/qa/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
