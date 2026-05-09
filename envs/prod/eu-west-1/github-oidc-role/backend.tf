terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "iam/prod/eu-west-1/github-oidc-role/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
