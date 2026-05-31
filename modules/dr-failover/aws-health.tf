####################################
## Tier-1 alarms: AWS Health feed  ##
####################################
# AWS publishes events to your account's default EventBridge bus when there's
# an AWS-side incident affecting services you use (regional outages, scheduled
# maintenance, security notifications).
#
# Two EventBridge rules:
#   - eu-west-1: catch events scoped to the source region.
#   - eu-central-1 (default): catch events scoped to DR region OR
#     account-wide / global events.
#
# Each rule routes to its local dr-alerts SNS topic — so on-call gets paged
# the moment AWS publishes anything relevant.
#
# Zero false positives: AWS only publishes Health events when there's a real
# incident or planned event in their infrastructure.

####################################################
# 1. EventBridge rule in eu-west-1 (source region) #
####################################################
resource "aws_cloudwatch_event_rule" "aws_health_source" {
  provider = aws.source

  name        = "${var.name_prefix}-aws-health-source"
  description = "Route AWS Health Dashboard events for ${var.source_region} to dr-alerts SNS."

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
    detail = {
      service = [
        "EC2", "RDS", "EKS", "EFS", "ELASTICLOADBALANCING",
        "ROUTE53", "VPC", "KMS", "SECRETSMANAGER", "S3",
        "CLOUDWATCH", "LAMBDA",
      ]
      eventScopeCode = ["PUBLIC", "ACCOUNT_SPECIFIC"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "aws_health_source_to_sns" {
  provider = aws.source

  rule      = aws_cloudwatch_event_rule.aws_health_source.name
  arn       = aws_sns_topic.dr_alerts_source.arn
  target_id = "send-to-dr-alerts-source"
}

# Permit EventBridge to publish to the SNS topic.
resource "aws_sns_topic_policy" "dr_alerts_source_eventbridge" {
  provider = aws.source

  arn = aws_sns_topic.dr_alerts_source.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgePublishSourceHealth"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.dr_alerts_source.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.aws_health_source.arn
          }
        }
      },
      {
        Sid       = "AllowCloudWatchAlarmsPublishSource"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.dr_alerts_source.arn
      },
    ]
  })
}

###############################################################
# 2. EventBridge rule in eu-central-1 (DR region + global)    #
###############################################################
resource "aws_cloudwatch_event_rule" "aws_health_dr" {
  name        = "${var.name_prefix}-aws-health-dr"
  description = "Route AWS Health events for ${var.dr_region} and global events to dr-alerts SNS."

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
    detail = {
      service = [
        "EC2", "RDS", "EKS", "EFS", "ELASTICLOADBALANCING",
        "ROUTE53", "VPC", "KMS", "SECRETSMANAGER", "S3",
        "CLOUDWATCH", "LAMBDA",
      ]
      eventScopeCode = ["PUBLIC", "ACCOUNT_SPECIFIC"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "aws_health_dr_to_sns" {
  rule      = aws_cloudwatch_event_rule.aws_health_dr.name
  arn       = aws_sns_topic.dr_alerts.arn
  target_id = "send-to-dr-alerts-dr"
}

resource "aws_sns_topic_policy" "dr_alerts_eventbridge" {
  arn = aws_sns_topic.dr_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgePublishDrHealth"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.dr_alerts.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.aws_health_dr.arn
          }
        }
      },
      {
        Sid       = "AllowCloudWatchAlarmsPublishDr"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.dr_alerts.arn
      },
    ]
  })
}

# Route53 alarm lives in us-east-1 and publishes to the us-east-1 dr-alerts topic.
resource "aws_sns_topic_policy" "dr_alerts_us_east_1_cloudwatch" {
  provider = aws.us_east_1

  arn = aws_sns_topic.dr_alerts_us_east_1.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAlarmsPublishUseast1"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.dr_alerts_us_east_1.arn
    }]
  })
}
