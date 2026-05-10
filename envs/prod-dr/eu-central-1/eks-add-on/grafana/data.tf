data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod-dr/eu-central-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "managed_prometheus" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks-add-on/prod-dr/eu-central-1/managed-prometheus/terraform.tfstate"
    region = "us-east-1"
  }
}
