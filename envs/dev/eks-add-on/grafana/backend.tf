terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "eks-add-on/grafana/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
