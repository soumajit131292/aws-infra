terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/managed-prometheus/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
