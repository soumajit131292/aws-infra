###############################
## Tier-1 alarms: EFS layer   ##
###############################
# One alarm:
#
#   TimeSinceLastSync (destination EFS, eu-central-1) — published in seconds
#   since the last successful replication of data from the source EFS.
#   Equivalent to Aurora's replication-lag metric, but for the EFS layer.
#
# A growing TimeSinceLastSync indicates:
#   - Source EFS unreachable from the replication service
#   - Source region network issue
#   - Replication itself paused/broken
#   - Source/destination KMS key issue
#
# All of these are early-warning signals of source-region instability.
#
# Note: this metric is published ONLY on the DESTINATION EFS. There is no
# AWS/EFS metric directly equivalent on the source side (the source EFS
# doesn't know it's being replicated FROM).

resource "aws_cloudwatch_metric_alarm" "efs_replication_lag" {
  alarm_name          = "${var.name_prefix}-efs-replication-lag-high"
  alarm_description   = "EFS cross-region replication is lagging — destination EFS has not synced from source in over ${var.efs_replication_lag_threshold_sec}s. Possible source-region trouble."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.efs_replication_lag_evaluation_periods
  datapoints_to_alarm = var.efs_replication_lag_datapoints_to_alarm
  metric_name         = "TimeSinceLastSync"
  namespace           = "AWS/EFS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.efs_replication_lag_threshold_sec
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = var.dr_efs_id
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = var.tags
}
