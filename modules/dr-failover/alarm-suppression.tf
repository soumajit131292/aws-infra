###############################################
## Phase 2: deployment-aware alarm suppression ##
###############################################
# When ArgoCD starts syncing, the alarm-actions-controller Lambda
# disables alarm actions (SNS publishes) on all Tier-1 alarms.
# When ArgoCD reports the app Healthy+Synced, it re-enables them.
# Failsafe: EventBridge schedule re-runs the Lambda every 10 min;
# if a deploy has been "in progress" longer than MAX_DISABLED_AGE_SEC,
# alarms are force-re-enabled.

# Single-row state table; uses DynamoDB TTL to auto-cleanup stuck rows.
resource "aws_dynamodb_table" "alarm_suppression_state" {
  name         = "${var.name_prefix}-alarm-suppression-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, { Purpose = "DR alarm suppression state" })
}

# Lambda code package
data "archive_file" "alarm_actions_controller" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/alarm_actions_controller"
  output_path = "${path.module}/lambdas/alarm_actions_controller.zip"
}

# IAM role for the Lambda
resource "aws_iam_role" "alarm_actions_controller" {
  name = "${var.name_prefix}-alarm-actions-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alarm_actions_controller_logs" {
  role       = aws_iam_role.alarm_actions_controller.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "alarm_actions_controller" {
  name = "${var.name_prefix}-alarm-actions-controller-policy"
  role = aws_iam_role.alarm_actions_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageAlarmActions"
        Effect = "Allow"
        Action = [
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:DescribeAlarms",
        ]
        Resource = "*" # Cross-region; scoped by alarm name in code, but IAM is *
      },
      {
        Sid    = "StateTable"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = aws_dynamodb_table.alarm_suppression_state.arn
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "alarm_actions_controller" {
  name              = "/aws/lambda/${var.name_prefix}-alarm-actions-controller"
  retention_in_days = 30
  tags              = var.tags
}

locals {
  # Map of alarm names per region. The Lambda iterates this dict and disables
  # actions in each region. Keep in sync with the alarms defined in
  # detection.tf, alarms-alb.tf, alarms-aurora.tf, alarms-efs.tf.
  alarm_inventory = {
    (var.source_region) = compact([
      aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
      aws_cloudwatch_metric_alarm.alb_target_5xx.alarm_name,
      try(aws_cloudwatch_metric_alarm.aurora_no_connections[0].alarm_name, ""),
      aws_cloudwatch_metric_alarm.aurora_db_load_high.alarm_name,
    ])
    (var.dr_region) = [
      aws_cloudwatch_metric_alarm.aurora_replication_lag.alarm_name,
      aws_cloudwatch_metric_alarm.efs_replication_lag.alarm_name,
    ]
    "us-east-1" = [
      aws_cloudwatch_metric_alarm.prod_app_unhealthy.alarm_name,
    ]
  }
}

resource "aws_lambda_function" "alarm_actions_controller" {
  function_name = "${var.name_prefix}-alarm-actions-controller"
  role          = aws_iam_role.alarm_actions_controller.arn
  runtime       = "python3.11"
  handler       = "main.lambda_handler"
  memory_size   = 256
  timeout       = 60

  filename         = data.archive_file.alarm_actions_controller.output_path
  source_code_hash = data.archive_file.alarm_actions_controller.output_base64sha256

  environment {
    variables = {
      ALARM_INVENTORY       = jsonencode(local.alarm_inventory)
      STATE_TABLE_NAME      = aws_dynamodb_table.alarm_suppression_state.name
      WEBHOOK_SHARED_SECRET = var.argocd_webhook_secret
      MIN_SUPPRESSION_SEC   = tostring(var.alarm_suppression_min_hold_seconds)
      MAX_DISABLED_AGE_SEC  = tostring(var.alarm_suppression_max_age_seconds)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.alarm_actions_controller,
    aws_iam_role_policy.alarm_actions_controller,
  ]

  tags = var.tags
}

####################################
# API Gateway HTTP API for webhook #
####################################
resource "aws_apigatewayv2_api" "argocd_webhook" {
  name          = "${var.name_prefix}-argocd-webhook"
  protocol_type = "HTTP"
  description   = "Receives ArgoCD Notifications webhooks to disable/enable alarm actions during deploys."
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "argocd_webhook" {
  api_id                 = aws_apigatewayv2_api.argocd_webhook.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.alarm_actions_controller.invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

resource "aws_apigatewayv2_route" "argocd_webhook" {
  api_id    = aws_apigatewayv2_api.argocd_webhook.id
  route_key = "POST /argocd-webhook"
  target    = "integrations/${aws_apigatewayv2_integration.argocd_webhook.id}"
}

resource "aws_apigatewayv2_stage" "argocd_webhook_default" {
  api_id      = aws_apigatewayv2_api.argocd_webhook.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 10
  }

  tags = var.tags
}

resource "aws_lambda_permission" "argocd_webhook_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_actions_controller.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.argocd_webhook.execution_arn}/*/*"
}

####################################
# EventBridge failsafe schedule    #
####################################
resource "aws_cloudwatch_event_rule" "alarm_suppression_failsafe" {
  name                = "${var.name_prefix}-alarm-suppression-failsafe"
  description         = "Every 10 min, ask the Lambda to force-enable alarm actions if disabled too long."
  schedule_expression = "rate(10 minutes)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "alarm_suppression_failsafe" {
  rule      = aws_cloudwatch_event_rule.alarm_suppression_failsafe.name
  arn       = aws_lambda_function.alarm_actions_controller.arn
  target_id = "alarm-actions-controller-failsafe"
}

resource "aws_lambda_permission" "alarm_suppression_failsafe_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_actions_controller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_suppression_failsafe.arn
}
