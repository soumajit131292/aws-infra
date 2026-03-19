terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/external-secrets-dr/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
