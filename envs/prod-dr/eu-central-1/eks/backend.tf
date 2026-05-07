terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks/prod-dr/eu-central-1/control-plane/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
