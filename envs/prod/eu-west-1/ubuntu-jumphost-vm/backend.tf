terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "compute/prod/eu-west-1/ubuntu-jumphost-vm/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
