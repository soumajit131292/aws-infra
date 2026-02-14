terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "database/aurora-postgres/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
