terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "compute/prod-dr/eu-central-1/ubuntu-jumphost-vm/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
