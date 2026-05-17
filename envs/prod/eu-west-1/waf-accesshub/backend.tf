terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "waf/prod/eu-west-1/accesshub/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
