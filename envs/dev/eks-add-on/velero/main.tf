locals {
  cluster_name                 = data.terraform_remote_state.eks.outputs.cluster_name
  oidc_provider_arn            = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer_url              = data.terraform_remote_state.eks.outputs.oidc_issuer_url
  oidc_issuer_hostpath         = replace(local.oidc_issuer_url, "https://", "")
  backup_bucket_name_effective = trimspace(var.backup_bucket_name) != "" ? trimspace(var.backup_bucket_name) : format("%s-%s-%s", var.backup_bucket_name_prefix, data.aws_caller_identity.current.account_id, var.region)
}

resource "aws_s3_bucket" "velero" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = local.backup_bucket_name_effective

  tags = merge(var.tags, {
    Name = local.backup_bucket_name_effective
  })
}

resource "aws_s3_bucket_public_access_block" "velero" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = aws_s3_bucket.velero[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "velero" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = aws_s3_bucket.velero[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "velero_assume_role" {
  statement {
    sid     = "EKSIRSA"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.velero_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "velero_irsa" {
  name               = "${local.cluster_name}-velero-irsa"
  assume_role_policy = data.aws_iam_policy_document.velero_assume_role.json
}

data "aws_iam_policy_document" "velero_permissions" {
  statement {
    sid    = "VeleroS3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${local.backup_bucket_name_effective}",
      "arn:aws:s3:::${local.backup_bucket_name_effective}/*"
    ]
  }

  statement {
    sid    = "VeleroEBSAccess"
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "velero_permissions" {
  name   = "${local.cluster_name}-velero-irsa-inline"
  role   = aws_iam_role.velero_irsa.id
  policy = data.aws_iam_policy_document.velero_permissions.json
}

resource "kubernetes_namespace" "velero" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "velero" {
  metadata {
    name      = var.velero_service_account_name
    namespace = kubernetes_namespace.velero.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.velero_irsa.arn
    }

    labels = {
      "app.kubernetes.io/name" = "velero"
    }
  }

  automount_service_account_token = true
}

module "velero_helm" {
  source = "../../../../modules/eks-velero"

  release_name            = var.helm_release_name
  namespace               = kubernetes_namespace.velero.metadata[0].name
  use_local_chart         = var.use_local_chart
  chart_version           = var.velero_chart_version
  service_account_name    = kubernetes_service_account.velero.metadata[0].name
  backup_bucket_name      = local.backup_bucket_name_effective
  aws_region              = var.region
  velero_image_repository = var.velero_image_repository
  velero_image_tag        = var.velero_image_tag
  aws_plugin_image        = var.velero_plugin_image

  depends_on = [
    aws_iam_role_policy.velero_permissions,
    kubernetes_service_account.velero,
    aws_s3_bucket_versioning.velero
  ]
}

moved {
  from = helm_release.velero
  to   = module.velero_helm.helm_release.velero
}
