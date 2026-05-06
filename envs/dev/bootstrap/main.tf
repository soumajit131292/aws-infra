module "github_oidc" {
  source = "../../../modules/github-oidc-provider"

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "GitHub OIDC"
  }
}

