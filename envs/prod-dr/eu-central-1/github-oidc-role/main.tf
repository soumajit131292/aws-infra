provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "github_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/accesshub/*",
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/thirdparty/*"
    ]
  }
}

module "github_actions_role" {
  source = "../../../../modules/github-oidc-role"

  role_name        = var.role_name
  github_org       = var.github_org
  github_repo      = var.github_repo
  allowed_branches = var.allowed_branches

  inline_policy_json = data.aws_iam_policy_document.github_policy.json

  tags = {
    Environment = "prod-dr"
    ManagedBy   = "terraform"
  }
}
