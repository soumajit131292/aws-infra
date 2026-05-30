###############################
## Step Functions             ##
###############################
# Standard workflow (not Express) — full execution history retained for audit.
# State machine definition inline using jsonencode() so all references are
# Terraform-managed (no separate ASL file to keep in sync).

# IAM role assumed by the state machine.
resource "aws_iam_role" "sfn" {
  name = "${var.name_prefix}-state-machine"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "sfn" {
  name = "${var.name_prefix}-state-machine"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Invoke each Lambda
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          for k, l in aws_lambda_function.lambdas : l.arn
        ]
      },
      # Publish to SNS topics
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [
          aws_sns_topic.dr_approval.arn,
          aws_sns_topic.dr_complete.arn,
        ]
      },
      # CloudWatch Logs for execution logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/stepfunctions/${var.name_prefix}"
  retention_in_days = 90
  tags              = var.tags
}

locals {
  # Convenience refs into the lambdas map.
  lambda_arn = { for k, l in aws_lambda_function.lambdas : k => l.arn }

  # Approval URLs given to the operator in the SNS message.
  approval_base_url = "${aws_apigatewayv2_api.approval.api_endpoint}/approve"

  state_machine_definition = {
    Comment = "AccessHub DR Failover orchestration. See modules/dr-failover/ README for triggering."
    StartAt = "PreFlightChecks"
    States = {

      # ─── Step 1 ───────────────────────────────────────────────────────────
      PreFlightChecks = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = local.lambda_arn["preflight_checks"]
          "Payload.$"  = "$"
        }
        ResultPath = "$.preflight"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "ManualApprovalGate"
      }

      # ─── Step 2 ───────────────────────────────────────────────────────────
      ManualApprovalGate = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish.waitForTaskToken"
        Parameters = {
          TopicArn    = aws_sns_topic.dr_approval.arn
          Subject     = "DR FAILOVER APPROVAL REQUIRED — AccessHub"
          "Message.$" = "States.Format('Pre-flight passed. Approve or deny the DR failover.\n\n  APPROVE: ${local.approval_base_url}?action=approve&sig=${var.approval_shared_secret}&token={}\n\n  DENY:    ${local.approval_base_url}?action=deny&sig=${var.approval_shared_secret}&token={}\n\nApproval window: ${tostring(var.approval_timeout_seconds)}s.\n\nPre-flight results:\n{}', $$.Task.Token, $$.Task.Token, States.JsonToString($.preflight))"
        }
        TimeoutSeconds = var.approval_timeout_seconds
        ResultPath     = "$.approval"
        Catch = [
          {
            ErrorEquals = ["States.Timeout"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          },
          {
            ErrorEquals = ["ApprovalDenied"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          },
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "AuroraFailover"
      }

      # ─── Step 3 ───────────────────────────────────────────────────────────
      AuroraFailover = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = local.lambda_arn["aurora_failover"]
          Payload = {
            "mode.$"    = "$.mode"
            "dry_run.$" = "$.dry_run"
          }
        }
        ResultPath = "$.aurora"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 15
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "EFSPromote"
      }

      # ─── Step 4 ───────────────────────────────────────────────────────────
      EFSPromote = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = local.lambda_arn["efs_promote"]
          Payload      = { "dry_run.$" = "$.dry_run" }
        }
        ResultPath = "$.efs"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "ScaleEKS"
      }

      # ─── Step 5 ───────────────────────────────────────────────────────────
      ScaleEKS = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = local.lambda_arn["eks_scale"]
          Payload = {
            "dry_run.$"             = "$.dry_run"
            "target_node_desired.$" = "$.target_node_desired"
            "target_replicas.$"     = "$.target_replicas"
          }
        }
        ResultPath = "$.eks"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 15
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "SkipWaitIfDryRun"
      }

      # ─── Step 6.25 — in dry-run, skip the ArgoCD wait (no reconcile to wait for) ──
      SkipWaitIfDryRun = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.dry_run"
            BooleanEquals = true
            Next          = "PostFailoverValidation"
          }
        ]
        Default = "WaitForArgoCD"
      }

      # ─── Step 6.5 — give ArgoCD time to reconcile + pods to come up ──────
      WaitForArgoCD = {
        Type    = "Wait"
        Seconds = 300
        Next    = "PostFailoverValidation"
      }

      # ─── Step 7 ───────────────────────────────────────────────────────────
      PostFailoverValidation = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = local.lambda_arn["post_failover_validation"]
          Payload      = { "dry_run.$" = "$.dry_run" }
        }
        ResultPath = "$.validation"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 30
            MaxAttempts     = 5
            BackoffRate     = 1.5
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "FailureNotification"
          }
        ]
        Next = "SuccessNotification"
      }

      # ─── Step 8 — success notification ────────────────────────────────────
      SuccessNotification = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = aws_sns_topic.dr_complete.arn
          Subject     = "DR FAILOVER COMPLETE — AccessHub is now active in prod-dr"
          "Message.$" = "States.Format('DR failover completed successfully.\n\nAurora: {}\nEFS: {}\nEKS: {}\nValidation: {}', States.JsonToString($.aurora.Payload), States.JsonToString($.efs.Payload), States.JsonToString($.eks.Payload), States.JsonToString($.validation.Payload))"
        }
        End = true
      }

      # ─── Failure path ────────────────────────────────────────────────────
      FailureNotification = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = aws_sns_topic.dr_complete.arn
          Subject     = "DR FAILOVER FAILED — AccessHub remains on primary"
          "Message.$" = "States.Format('DR failover did NOT complete.\n\nError: {}\n\nLast input state: {}', States.JsonToString($.error), States.JsonToString($))"
        }
        Next = "FailState"
      }

      FailState = {
        Type  = "Fail"
        Error = "DRFailoverFailed"
        Cause = "Failover aborted; see SNS message and Step Functions execution history."
      }
    }
  }
}

resource "aws_sfn_state_machine" "dr_failover" {
  name     = "${var.name_prefix}-state-machine"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  definition = jsonencode(local.state_machine_definition)

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  depends_on = [
    aws_iam_role_policy.sfn,
    aws_cloudwatch_log_group.sfn,
  ]

  tags = var.tags
}
