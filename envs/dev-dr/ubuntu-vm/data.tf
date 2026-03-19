data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/vpc-dr/terraform.tfstate"
    region = "us-west-1"
  }
}
