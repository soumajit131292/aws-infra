data "aws_caller_identity" "current" {}

data "terraform_remote_state" "alb_controller" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks-add-on/prod/eu-west-1/alb-controller/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "security_log_pipeline" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "security/prod/eu-west-1/log-pipeline/terraform.tfstate"
    region = "us-east-1"
  }
}
