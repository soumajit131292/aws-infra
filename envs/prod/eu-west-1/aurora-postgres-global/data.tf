data "terraform_remote_state" "prod_aurora" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "database/prod/eu-west-1/aurora-postgres/terraform.tfstate"
    region = "us-east-1"
  }
}
