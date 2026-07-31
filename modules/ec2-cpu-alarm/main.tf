##############################################################################
## CPU-utilization alarm for standalone EC2 servers (pets) -> SNS email.
##
## Intended for long-lived, individually-managed instances (e.g. the Wazuh and
## Zeek sensor VMs) where a per-instance CPU alarm is meaningful. NOT for EKS
## node-group instances -- those are ephemeral/autoscaled and should be alerted
## via cluster saturation/health signals (Prometheus/Container Insights), not
## per-instance CPU.
##############################################################################

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "this" {
  name = "${var.name_prefix}-cpu-alerts"
  tags = var.tags
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAlarmsPublish"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.this.arn
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  for_each = var.instances

  alarm_name          = "${each.key}-cpu-high"
  alarm_description   = "Average CPUUtilization high on ${each.key} (${each.value})."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold_percent
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}
