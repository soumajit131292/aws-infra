terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "bootstrap/oidc-provider/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
