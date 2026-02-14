provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "github_policy" {

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["*"]
  }
}

module "github_actions_role" {
  source = "../../../modules/github-oidc-role"

  role_name        = "github-actions-crave-repo"
  github_org       = var.github_org
  github_repo      = var.github_repo
  allowed_branches = ["main"]

  inline_policy_json = data.aws_iam_policy_document.github_policy.json

  tags = {
    Environment = "prod"
  }
}
