terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "github-oidc-role/oidc-provider-role/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
