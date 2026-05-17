terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "acm/prod-dr/eu-central-1/accesshub-identity/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
