##############################################################################
## DynamoDB alarms for the alarm-suppression-state table.
##
## Added to satisfy the "NoSQL storage utilization is monitored with alerts to
## personnel at thresholds" requirement. Note: this is a small, serverless
## (PAY_PER_REQUEST), TTL'd utility table whose storage stays near-zero, so the
## storage alarm is primarily a compliance + sanity signal (it would only fire
## if TTL cleanup broke or the table grew unexpectedly). Throttle alarms are the
## operationally meaningful ones. All route to the same dr_alerts SNS topic.
##############################################################################

variable "dynamodb_table_size_threshold_bytes" {
  description = "Alarm when the alarm-suppression table size exceeds this (bytes). Default 500 MB — the table should stay tiny."
  type        = number
  default     = 524288000
}

# "Storage utilization" signal (TableSizeBytes is published ~every 6 hours).
resource "aws_cloudwatch_metric_alarm" "ddb_suppression_storage" {
  alarm_name          = "${var.name_prefix}-ddb-suppression-storage-high"
  alarm_description   = "alarm-suppression-state table storage unexpectedly high."
  namespace           = "AWS/DynamoDB"
  metric_name         = "TableSizeBytes"
  dimensions          = { TableName = aws_dynamodb_table.alarm_suppression_state.name }
  statistic           = "Maximum"
  period              = 21600
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.dynamodb_table_size_threshold_bytes
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ddb_suppression_read_throttle" {
  alarm_name          = "${var.name_prefix}-ddb-suppression-read-throttle"
  alarm_description   = "Read throttling on the alarm-suppression-state table."
  namespace           = "AWS/DynamoDB"
  metric_name         = "ReadThrottleEvents"
  dimensions          = { TableName = aws_dynamodb_table.alarm_suppression_state.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ddb_suppression_write_throttle" {
  alarm_name          = "${var.name_prefix}-ddb-suppression-write-throttle"
  alarm_description   = "Write throttling on the alarm-suppression-state table."
  namespace           = "AWS/DynamoDB"
  metric_name         = "WriteThrottleEvents"
  dimensions          = { TableName = aws_dynamodb_table.alarm_suppression_state.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = var.tags
}
