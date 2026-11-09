data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "eks/prod/eu-west-1/control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}

# Read-only: only the manager's private IP is consumed. Nothing in this stack
# changes the Wazuh server.
data "terraform_remote_state" "wazuh" {
  backend = "s3"

  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "security/prod/eu-west-1/wazuh/terraform.tfstate"
    region = "us-east-1"
  }
}
