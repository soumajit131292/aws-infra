terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "monitoring/dev/aurora-alarms/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
