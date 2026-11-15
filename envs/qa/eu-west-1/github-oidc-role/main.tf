provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ecr_arn_prefix = "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository"
}

# QA pushes only to its own accesshub-qa/* repositories (envs/qa/eu-west-1/ecr).
# It can read, but never write, the shared base images the Dockerfiles build
# FROM: thirdparty/* and the health-aggregator python base, which lives at
# accesshub/health-aggregator:python-3.12-slim-amd64-platform.
data "aws_iam_policy_document" "github_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushQaImages"
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
    resources = ["${local.ecr_arn_prefix}/accesshub-qa/*"]
  }

  statement {
    sid    = "PullBaseImages"
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      "${local.ecr_arn_prefix}/thirdparty/*",
      "${local.ecr_arn_prefix}/accesshub/health-aggregator"
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
    Environment = "qa"
    ManagedBy   = "terraform"
  }
}
