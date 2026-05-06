terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "compute/ubuntu-vm/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
