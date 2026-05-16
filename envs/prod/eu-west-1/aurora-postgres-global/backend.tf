terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "aurora/prod/eu-west-1/global-cluster/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
