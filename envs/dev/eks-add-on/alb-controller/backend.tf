terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/alb-controller/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
