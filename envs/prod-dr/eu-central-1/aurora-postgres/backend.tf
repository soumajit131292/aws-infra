terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "database/prod-dr/eu-central-1/aurora-postgres/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
