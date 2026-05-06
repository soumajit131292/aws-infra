terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "dns/route53-accesshub/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
