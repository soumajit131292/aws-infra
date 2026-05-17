data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/prod/eu-west-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_secretsmanager_secret" "db_credentials" {
  count = var.db_credentials_secret_name != "" ? 1 : 0
  name  = var.db_credentials_secret_name
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  count         = var.db_credentials_secret_name != "" ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.db_credentials[0].id
  version_stage = var.db_credentials_secret_version_stage
}
