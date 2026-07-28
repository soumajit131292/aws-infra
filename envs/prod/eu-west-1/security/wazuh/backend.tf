terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "security/prod/eu-west-1/wazuh/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
