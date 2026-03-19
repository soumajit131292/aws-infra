terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "compute/ubuntu-vm-dr/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
