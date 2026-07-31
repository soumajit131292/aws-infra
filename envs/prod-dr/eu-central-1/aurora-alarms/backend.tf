terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "monitoring/prod-dr/eu-central-1/aurora-alarms/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
