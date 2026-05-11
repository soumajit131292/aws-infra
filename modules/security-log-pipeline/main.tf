data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

###############################
## KMS CMK for the log lake  ##
###############################
resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} security log archive CMK"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogsService"
        Effect    = "Allow"
        Principal = { Service = "logs.${var.region}.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.this.key_id
}

###############################
## S3 security log bucket    ##
###############################
resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  object_lock_enabled = var.object_lock_enabled

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "tiering-and-expiration"
    status = "Enabled"

    filter {}

    transition {
      days          = var.lifecycle_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.lifecycle_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    dynamic "expiration" {
      for_each = var.lifecycle_expiration_days > 0 ? [1] : []
      content {
        days = var.lifecycle_expiration_days
      }
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" }
        }
      }
    ]
  })
}

##########################################
## Firehose IAM role (writes to S3+KMS) ##
##########################################
resource "aws_iam_role" "firehose" {
  name = "${var.name_prefix}-security-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "firehose" {
  name = "${var.name_prefix}-security-firehose"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Write"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Sid    = "KmsEncrypt"
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.this.arn
      },
      {
        Sid    = "FirehoseErrorLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [for k, v in var.log_subscriptions :
          "arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:/aws/kinesisfirehose/${var.name_prefix}-${k}:log-stream:*"
        ]
      }
    ]
  })
}

###############################################
## CloudWatch Logs role (subscription -> FH) ##
###############################################
resource "aws_iam_role" "cwlogs_to_firehose" {
  name = "${var.name_prefix}-cwlogs-to-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "logs.${var.region}.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cwlogs_to_firehose" {
  name = "${var.name_prefix}-cwlogs-to-firehose"
  role = aws_iam_role.cwlogs_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ]
      Resource = [for k, v in var.log_subscriptions :
        "arn:${local.partition}:firehose:${var.region}:${local.account_id}:deliverystream/${var.name_prefix}-${k}"
      ]
    }]
  })
}

##############################################
## Per-subscription: error LG, FH, sub fltr ##
##############################################
resource "aws_cloudwatch_log_group" "firehose_errors" {
  for_each = var.log_subscriptions

  name              = "/aws/kinesisfirehose/${var.name_prefix}-${each.key}"
  retention_in_days = var.firehose_error_log_retention_days

  tags = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  for_each = var.log_subscriptions

  name        = "${var.name_prefix}-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn    = aws_iam_role.firehose.arn
    bucket_arn  = aws_s3_bucket.this.arn
    kms_key_arn = aws_kms_key.this.arn

    prefix              = "${each.value.s3_prefix}year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/${each.key}/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    buffering_size     = var.firehose_buffer_size_mb
    buffering_interval = var.firehose_buffer_interval_seconds
    compression_format = var.firehose_compression_format

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_errors[each.key].name
      log_stream_name = "S3Delivery"
    }
  }

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = aws_kms_key.this.arn
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.firehose
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  for_each = var.log_subscriptions

  name            = "${var.name_prefix}-${each.key}-to-firehose"
  log_group_name  = each.value.log_group_name
  filter_pattern  = each.value.filter_pattern
  destination_arn = aws_kinesis_firehose_delivery_stream.this[each.key].arn
  role_arn        = aws_iam_role.cwlogs_to_firehose.arn

  depends_on = [
    aws_iam_role_policy.cwlogs_to_firehose
  ]
}
