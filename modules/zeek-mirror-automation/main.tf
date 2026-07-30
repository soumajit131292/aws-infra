##############################################################################
## Zeek mirror automation: keep VPC Traffic Mirror sessions in sync with the
## live EKS worker nodes.
##
## A Lambda runs a full reconcile on every invocation (create sessions for new
## node ENIs, delete sessions for gone nodes). It is triggered by:
##   - EC2 instance state-change events (node launch/terminate), and
##   - a scheduled rule (safety net + initial backfill).
##
## This replaces the static source_network_interface_ids list on the Zeek
## sensor: with automation on, leave that list empty and let the Lambda manage
## sessions as the managed node group scales/recycles.
##############################################################################

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/${var.name}.zip"
}

########################
## IAM role for Lambda ##
########################
resource "aws_iam_role" "this" {
  name = "${var.name}-role"

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

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role_policy" "this" {
  name = "${var.name}-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeForReconcile"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTrafficMirrorSessions",
          "ec2:DescribeTrafficMirrorTargets",
          "ec2:DescribeTrafficMirrorFilters"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageMirrorSessions"
        Effect = "Allow"
        Action = [
          "ec2:CreateTrafficMirrorSession",
          "ec2:DeleteTrafficMirrorSession",
          "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      }
    ]
  })
}

####################
## Lambda function ##
####################
resource "aws_lambda_function" "this" {
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 120
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME     = var.cluster_name
      MIRROR_TARGET_ID = var.mirror_target_id
      MIRROR_FILTER_ID = var.mirror_filter_id
      VNI              = tostring(var.vni)
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.this,
    aws_cloudwatch_log_group.this
  ]
}

##################################################
## EventBridge: node state-change + scheduled sweep
##################################################
resource "aws_cloudwatch_event_rule" "node_state_change" {
  name        = "${var.name}-node-state"
  description = "EKS node launch/terminate -> reconcile Zeek mirror sessions"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "terminated"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "node_state_change" {
  rule      = aws_cloudwatch_event_rule.node_state_change.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "node_state_change" {
  statement_id  = "AllowEventBridgeNodeState"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.node_state_change.arn
}

resource "aws_cloudwatch_event_rule" "scheduled_sweep" {
  name                = "${var.name}-sweep"
  description         = "Periodic reconcile of Zeek mirror sessions (safety net + backfill)"
  schedule_expression = var.sweep_schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "scheduled_sweep" {
  rule      = aws_cloudwatch_event_rule.scheduled_sweep.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "scheduled_sweep" {
  statement_id  = "AllowEventBridgeSweep"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_sweep.arn
}
