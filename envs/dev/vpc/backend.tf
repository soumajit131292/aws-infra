terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "network/vpc/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
