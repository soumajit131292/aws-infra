data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
