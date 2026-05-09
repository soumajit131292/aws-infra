terraform {
  backend "s3" {
    bucket  = "crave-infra-terraform-state-bucket"
    key     = "dns/prod/eu-west-1/route53-accesshub/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
