module "alb_controller" {
  source = "../../../../../modules/eks-alb-controller"

  cluster_name     = data.terraform_remote_state.eks.outputs.cluster_name
  region           = var.region
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  alb_iam_role_arn = data.terraform_remote_state.eks.outputs.alb_controller_role_arn

  tags = {
    component = "alb-controller"
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  alb_access_logs_bucket_name_effective = trimspace(var.alb_access_logs_bucket_name) != "" ? trimspace(var.alb_access_logs_bucket_name) : format("%s-%s-%s", var.alb_access_logs_bucket_name_prefix, data.aws_caller_identity.current.account_id, data.aws_region.current.name)

  alb_access_logs_prefix_effective = trimspace(var.alb_access_logs_prefix)

  alb_access_logs_annotation = format(
    "access_logs.s3.enabled=true,access_logs.s3.bucket=%s,access_logs.s3.prefix=%s",
    local.alb_access_logs_bucket_name_effective,
    local.alb_access_logs_prefix_effective,
  )
}

resource "aws_s3_bucket" "alb_access_logs" {
  count = var.create_alb_access_logs_bucket ? 1 : 0

  bucket        = local.alb_access_logs_bucket_name_effective
  force_destroy = var.alb_access_logs_bucket_force_destroy

  tags = merge(var.tags, {
    Name      = local.alb_access_logs_bucket_name_effective
    component = "alb-access-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  count = var.create_alb_access_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  count = var.create_alb_access_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count = var.create_alb_access_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  depends_on = [aws_s3_bucket_ownership_controls.alb_access_logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = format(
          "arn:aws:s3:::%s/%s/AWSLogs/%s/*",
          local.alb_access_logs_bucket_name_effective,
          local.alb_access_logs_prefix_effective,
          data.aws_caller_identity.current.account_id,
        )
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  count = var.create_alb_access_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    id     = "alb-access-logs-retention"
    status = "Enabled"

    expiration {
      days = var.alb_access_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.alb_access_logs_noncurrent_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
