terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "dr-failover/prod-dr/eu-central-1/orchestration/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
