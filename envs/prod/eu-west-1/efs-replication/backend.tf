terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "efs/prod/eu-west-1/replication/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
