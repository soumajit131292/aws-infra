data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/control-plane-dr/terraform.tfstate"
    region = "us-west-1"
  }
}
