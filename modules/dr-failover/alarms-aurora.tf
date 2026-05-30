##################################
## Tier-1 alarms: Aurora layer  ##
##################################
# Three Aurora alarms:
#
#   1. Replication lag (DR side, eu-central-1) — fires if the prod->prod-dr
#      replication falls behind. Could indicate prod instability, network
#      issues, or replication-pipeline problems.
#
#   2. Database connections (prod side, eu-west-1) — if connections suddenly
#      drop to zero on the prod cluster, the app may have lost DB access
#      (network partition, security-group regression, or DB unreachable).
#      Only enabled when aurora_min_connections > 0.
#
#   3. Aurora DBLoad spike (prod side) — sustained high load may presage
#      collapse. Optional, useful for soft-failures.

##############################################################
# 1. Replication lag — published in the DESTINATION region   #
#    (prod-dr cluster, eu-central-1).                        #
##############################################################
resource "aws_cloudwatch_metric_alarm" "aurora_replication_lag" {
  alarm_name          = "${var.name_prefix}-aurora-replication-lag-high"
  alarm_description   = "Aurora Global Database replication lag from prod to prod-dr is elevated. Indicates possible prod cluster instability or cross-region network problems."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.aurora_replication_lag_evaluation_periods
  datapoints_to_alarm = var.aurora_replication_lag_datapoints_to_alarm
  metric_name         = "AuroraGlobalDBReplicationLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.aurora_replication_lag_threshold_ms
  treat_missing_data  = "breaching"

  dimensions = {
    DBClusterIdentifier = var.dr_cluster_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = var.tags
}

##############################################################
# 2. Database connections drop to ZERO on prod cluster       #
#    (only enabled if aurora_min_connections > 0)            #
##############################################################
resource "aws_cloudwatch_metric_alarm" "aurora_no_connections" {
  count    = var.aurora_min_connections > 0 ? 1 : 0
  provider = aws.source

  alarm_name          = "${var.name_prefix}-aurora-no-connections"
  alarm_description   = "Aurora prod cluster has zero or near-zero DatabaseConnections. App may have lost DB access (network partition / DB unreachable / SG regression)."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.aurora_no_connections_evaluation_periods
  datapoints_to_alarm = var.aurora_no_connections_datapoints_to_alarm
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.aurora_min_connections
  treat_missing_data  = "breaching"

  dimensions = {
    DBClusterIdentifier = var.prod_cluster_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts_source.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_source.arn]

  tags = var.tags
}

##############################################################
# 3. DBLoad spike on prod cluster — sustained overload       #
##############################################################
resource "aws_cloudwatch_metric_alarm" "aurora_db_load_high" {
  provider = aws.source

  alarm_name          = "${var.name_prefix}-aurora-db-load-high"
  alarm_description   = "Aurora prod cluster DBLoad is sustained high (>vCPUs). Possible runaway query, lock contention, or overload."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.aurora_db_load_evaluation_periods
  datapoints_to_alarm = var.aurora_db_load_datapoints_to_alarm
  metric_name         = "DBLoad"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.aurora_db_load_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = var.prod_cluster_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts_source.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_source.arn]

  tags = var.tags
}
