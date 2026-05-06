terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "network/prod-dr/eu-central-1/vpc/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
