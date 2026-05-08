terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/prod-dr/eu-central-1/node-monitoring/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
