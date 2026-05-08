terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/prod/eu-west-1/alb-controller/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
