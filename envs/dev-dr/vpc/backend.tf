terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "network/vpc-dr/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
