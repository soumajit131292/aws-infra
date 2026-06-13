data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition

  alb_logs_prefix_clean       = trimsuffix(trim(var.alb_logs_prefix, "/"), "/")
  athena_results_prefix_clean = trimsuffix(trim(var.athena_results_prefix, "/"), "/")

  alb_logs_location      = "s3://${var.alb_logs_bucket_name}/${local.alb_logs_prefix_clean}/AWSLogs/${var.account_id}/elasticloadbalancing/${var.region}/"
  athena_output_location = "s3://${var.athena_results_bucket_name}/${local.athena_results_prefix_clean}/"
  reader_policy_name     = trimspace(var.reader_policy_name) != "" ? trimspace(var.reader_policy_name) : "${var.name_prefix}-alb-log-athena-reader"
}

resource "aws_glue_catalog_database" "this" {
  name        = var.database_name
  description = "Athena database for ${var.name_prefix} ALB access logs."
}

resource "aws_glue_catalog_table" "alb_access_logs" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.this.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Application Load Balancer access logs stored in S3."

  parameters = {
    EXTERNAL                       = "TRUE"
    "classification"               = "alb"
    "projection.enabled"           = "true"
    "projection.day.type"          = "date"
    "projection.day.range"         = "${var.projection_start_date},NOW"
    "projection.day.format"        = "yyyy/MM/dd"
    "projection.day.interval"      = "1"
    "projection.day.interval.unit" = "DAYS"
    "storage.location.template"    = "${local.alb_logs_location}$${day}/"
    "skip.header.line.count"       = "0"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = local.alb_logs_location
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "${var.table_name}_serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

      parameters = {
        "input.regex" = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\\s]+?)\" \"([^\\s]+)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)? ?( .*)?"
      }
    }

    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "elb"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "client_port"
      type = "int"
    }
    columns {
      name = "target_ip"
      type = "string"
    }
    columns {
      name = "target_port"
      type = "int"
    }
    columns {
      name = "request_processing_time"
      type = "double"
    }
    columns {
      name = "target_processing_time"
      type = "double"
    }
    columns {
      name = "response_processing_time"
      type = "double"
    }
    columns {
      name = "elb_status_code"
      type = "int"
    }
    columns {
      name = "target_status_code"
      type = "string"
    }
    columns {
      name = "received_bytes"
      type = "bigint"
    }
    columns {
      name = "sent_bytes"
      type = "bigint"
    }
    columns {
      name = "request_verb"
      type = "string"
    }
    columns {
      name = "request_url"
      type = "string"
    }
    columns {
      name = "request_proto"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "target_group_arn"
      type = "string"
    }
    columns {
      name = "trace_id"
      type = "string"
    }
    columns {
      name = "domain_name"
      type = "string"
    }
    columns {
      name = "chosen_cert_arn"
      type = "string"
    }
    columns {
      name = "matched_rule_priority"
      type = "string"
    }
    columns {
      name = "request_creation_time"
      type = "string"
    }
    columns {
      name = "actions_executed"
      type = "string"
    }
    columns {
      name = "redirect_url"
      type = "string"
    }
    columns {
      name = "lambda_error_reason"
      type = "string"
    }
    columns {
      name = "target_port_list"
      type = "string"
    }
    columns {
      name = "target_status_code_list"
      type = "string"
    }
    columns {
      name = "classification"
      type = "string"
    }
    columns {
      name = "classification_reason"
      type = "string"
    }
    columns {
      name = "conn_trace_id"
      type = "string"
    }
  }
}

resource "aws_athena_workgroup" "this" {
  name        = var.athena_workgroup_name
  description = "Workgroup for querying ${var.name_prefix} ALB access logs."

  configuration {
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = local.athena_output_location

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.athena_results_kms_key_arn
      }
    }
  }

  tags = var.tags
}

resource "aws_athena_named_query" "recent_errors" {
  name        = "${var.name_prefix}-alb-recent-errors"
  database    = aws_glue_catalog_database.this.name
  workgroup   = aws_athena_workgroup.this.name
  description = "Recent ALB 4xx/5xx responses."

  query = <<-SQL
    SELECT
      time,
      client_ip,
      request_verb,
      request_url,
      elb_status_code,
      target_status_code,
      target_processing_time,
      trace_id
    FROM ${aws_glue_catalog_database.this.name}.${aws_glue_catalog_table.alb_access_logs.name}
    WHERE day BETWEEN date_format(current_date - interval '1' day, '%Y/%m/%d')
      AND date_format(current_date, '%Y/%m/%d')
      AND (elb_status_code >= 400 OR try_cast(target_status_code AS integer) >= 400)
    ORDER BY time DESC
    LIMIT 100;
  SQL
}

resource "aws_athena_named_query" "slow_requests" {
  name        = "${var.name_prefix}-alb-slow-requests"
  database    = aws_glue_catalog_database.this.name
  workgroup   = aws_athena_workgroup.this.name
  description = "Slowest target responses in the last two projected days."

  query = <<-SQL
    SELECT
      time,
      client_ip,
      request_verb,
      request_url,
      elb_status_code,
      target_status_code,
      target_processing_time,
      trace_id
    FROM ${aws_glue_catalog_database.this.name}.${aws_glue_catalog_table.alb_access_logs.name}
    WHERE day BETWEEN date_format(current_date - interval '1' day, '%Y/%m/%d')
      AND date_format(current_date, '%Y/%m/%d')
      AND target_processing_time >= 1
    ORDER BY target_processing_time DESC
    LIMIT 100;
  SQL
}

resource "aws_athena_named_query" "top_client_ips" {
  name        = "${var.name_prefix}-alb-top-client-ips"
  database    = aws_glue_catalog_database.this.name
  workgroup   = aws_athena_workgroup.this.name
  description = "Top client IPs for the current day."

  query = <<-SQL
    SELECT
      client_ip,
      count(*) AS request_count,
      count_if(elb_status_code >= 400 OR try_cast(target_status_code AS integer) >= 400) AS error_count
    FROM ${aws_glue_catalog_database.this.name}.${aws_glue_catalog_table.alb_access_logs.name}
    WHERE day = date_format(current_date, '%Y/%m/%d')
    GROUP BY client_ip
    ORDER BY request_count DESC
    LIMIT 50;
  SQL
}

resource "aws_iam_policy" "reader" {
  count = var.create_reader_policy ? 1 : 0

  name        = local.reader_policy_name
  description = "Read/query access for ${var.name_prefix} ALB logs through Athena."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AthenaQueryAccess"
        Effect = "Allow"
        Action = [
          "athena:BatchGetNamedQuery",
          "athena:BatchGetQueryExecution",
          "athena:GetNamedQuery",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetDataCatalog",
          "athena:GetWorkGroup",
          "athena:ListNamedQueries",
          "athena:ListQueryExecutions",
          "athena:ListWorkGroups",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = "*"
      },
      {
        Sid    = "GlueCatalogRead"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:GetTable",
          "glue:GetTables"
        ]
        Resource = [
          "arn:${local.partition}:glue:${var.region}:${var.account_id}:catalog",
          aws_glue_catalog_database.this.arn,
          aws_glue_catalog_table.alb_access_logs.arn
        ]
      },
      {
        Sid    = "ReadAlbLogObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:${local.partition}:s3:::${var.alb_logs_bucket_name}/${local.alb_logs_prefix_clean}/AWSLogs/${var.account_id}/elasticloadbalancing/${var.region}/*"
      },
      {
        Sid    = "ListAlbLogBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = "arn:${local.partition}:s3:::${var.alb_logs_bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = "${local.alb_logs_prefix_clean}/AWSLogs/${var.account_id}/elasticloadbalancing/${var.region}/*"
          }
        }
      },
      {
        Sid    = "AthenaResultsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "arn:${local.partition}:s3:::${var.athena_results_bucket_name}/${local.athena_results_prefix_clean}/*"
      },
      {
        Sid    = "ListAthenaResultsBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:${local.partition}:s3:::${var.athena_results_bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = "${local.athena_results_prefix_clean}/*"
          }
        }
      },
      {
        Sid    = "AthenaResultsKms"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.athena_results_kms_key_arn
      }
    ]
  })

  tags = var.tags
}
