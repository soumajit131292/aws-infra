locals {
  oidc_issuer_hostpath    = replace(data.terraform_remote_state.eks.outputs.oidc_issuer_url, "https://", "")
  resolved_irsa_role_name = var.irsa_role_name != "" ? var.irsa_role_name : "${data.terraform_remote_state.eks.outputs.cluster_name}-external-secrets-irsa"

  required_set = {
    "serviceAccount.create"                                     = "true"
    "serviceAccount.name"                                       = var.service_account_name
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.external_secrets_irsa.arn
  }
}

data "aws_iam_policy_document" "external_secrets_irsa_assume_role" {
  statement {
    sid     = "EKSIRSA"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_permissions" {
  statement {
    sid    = "SecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = var.secrets_manager_secret_arns
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arns) > 0 ? [1] : []
    content {
      sid       = "KMSDecrypt"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = var.kms_key_arns
    }
  }
}

resource "aws_iam_role" "external_secrets_irsa" {
  name               = local.resolved_irsa_role_name
  assume_role_policy = data.aws_iam_policy_document.external_secrets_irsa_assume_role.json
}

resource "aws_iam_role_policy" "external_secrets_permissions" {
  name   = "${local.resolved_irsa_role_name}-inline"
  role   = aws_iam_role.external_secrets_irsa.id
  policy = data.aws_iam_policy_document.external_secrets_permissions.json
}

module "external_secrets" {
  source = "../../../../modules/eks-eso"

  release_name     = var.release_name
  namespace        = var.namespace
  chart_path       = var.chart_path
  create_namespace = var.create_namespace
  manage_namespace = var.manage_namespace
  timeout          = var.timeout
  atomic           = var.atomic
  values_files     = var.values_files
  values           = var.values
  set              = merge(var.set, local.required_set)
}

resource "kubernetes_manifest" "cluster_secret_store" {
  count = var.create_cluster_secret_store ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store_name
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.service_account_name
                namespace = var.namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [module.external_secrets]
}
