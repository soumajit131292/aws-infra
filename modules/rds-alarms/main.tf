##############################################################################
## CloudWatch alarms for Aurora/RDS instances -> SNS email alerts.
##
## Creates, per DB instance, alarms on the AWS/RDS metrics:
##   - ReadLatency, ReadIOPS, ReadThroughput   (read I/O)
##   - CPUUtilization                          (server CPU use)
##   - FreeLocalStorage                        (free storage space)
## and routes them to an SNS topic whose subscribers are the "appropriate
## personnel". Backs the "X is monitored, with alerts to personnel at
## thresholds" statements. Extend with more metrics as needed.
##############################################################################

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "this" {
  name = "${var.name_prefix}-rds-io-alerts"
  tags = var.tags
}

# Allow CloudWatch alarms to publish to the topic.
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

locals {
  instances = toset(var.db_instance_identifiers)
}

resource "aws_cloudwatch_metric_alarm" "read_latency" {
  for_each = local.instances

  alarm_name          = "${var.name_prefix}-${each.value}-read-latency-high"
  alarm_description   = "Average ReadLatency high on ${each.value} (read I/O pressure)."
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.read_latency_threshold_seconds
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "read_iops" {
  for_each = local.instances

  alarm_name          = "${var.name_prefix}-${each.value}-read-iops-high"
  alarm_description   = "Average ReadIOPS high on ${each.value}."
  namespace           = "AWS/RDS"
  metric_name         = "ReadIOPS"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.read_iops_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "read_throughput" {
  for_each = local.instances

  alarm_name          = "${var.name_prefix}-${each.value}-read-throughput-high"
  alarm_description   = "Average ReadThroughput high on ${each.value} (bytes/sec)."
  namespace           = "AWS/RDS"
  metric_name         = "ReadThroughput"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.read_throughput_threshold_bytes
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  for_each = local.instances

  alarm_name          = "${var.name_prefix}-${each.value}-cpu-high"
  alarm_description   = "Average CPUUtilization high on ${each.value} (percent)."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_utilization_threshold_percent
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}

# Free storage: Aurora cluster storage auto-scales, so the meaningful "free
# storage" signal is per-instance local storage (temp/sort space). Alert when
# it drops BELOW the threshold.
resource "aws_cloudwatch_metric_alarm" "free_local_storage" {
  for_each = local.instances

  alarm_name          = "${var.name_prefix}-${each.value}-free-storage-low"
  alarm_description   = "FreeLocalStorage low on ${each.value} (bytes free)."
  namespace           = "AWS/RDS"
  metric_name         = "FreeLocalStorage"
  dimensions          = { DBInstanceIdentifier = each.value }
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  comparison_operator = "LessThanThreshold"
  threshold           = var.free_local_storage_threshold_bytes
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.this.arn]
  ok_actions    = [aws_sns_topic.this.arn]

  tags = var.tags
}
