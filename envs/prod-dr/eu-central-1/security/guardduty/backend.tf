terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "security/prod-dr/eu-central-1/guardduty/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
