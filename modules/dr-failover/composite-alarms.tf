#############################################################
## Composite alarms — high-signal "go-time" pagers          ##
#############################################################
# Composite alarms reduce false positives by requiring TWO
# independent signals to fire together. Singles still alert
# (ticket/email), but composites are what should page oncall.
#
# Constraint: a composite can only reference alarms in the
# SAME region. So we group by region.
#
# Composite #2 — Cross-region replication is collapsing
# -----------------------------------------------------
# Both alarms live in eu-central-1 (the DR side) and measure
# what's flowing *from* eu-west-1. They use independent
# transport (Aurora Global DB vs EFS Cross-Region Replication),
# so they only fire together when the source region or
# inter-region network is genuinely degrading — not on
# isolated service glitches.
#
# This is a LEADING indicator: replication often slows minutes
# before user-facing alarms (Route 53, ALB) fire.

resource "aws_cloudwatch_composite_alarm" "cross_region_replication_degraded" {
  alarm_name        = "${var.name_prefix}-COMPOSITE-cross-region-replication-degraded"
  alarm_description = <<-EOT
    PAGE ONCALL. Both Aurora Global DB replication AND EFS cross-region
    replication are lagging beyond threshold simultaneously. These two
    services use independent transport — both failing at once is a strong
    signal that the source region (eu-west-1) is degrading, or that the
    inter-region network is impaired. This is a leading indicator of a
    regional incident — Route 53 / ALB alarms may follow within minutes.

    Next steps:
      1. Open the DR overview dashboard.
      2. Check AWS Health Dashboard for eu-west-1 events.
      3. If both signals persist > 10 min AND user-facing alarms also fire,
         consider initiating the DR failover Step Functions execution.
  EOT

  alarm_rule = join(" AND ", [
    "ALARM(\"${aws_cloudwatch_metric_alarm.aurora_replication_lag.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.efs_replication_lag.alarm_name}\")",
  ])

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.dr_alerts.arn]
  ok_actions      = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.tags, {
    Severity = "P1"
    Purpose  = "Page oncall on cross-region replication collapse"
  })

  depends_on = [
    aws_cloudwatch_metric_alarm.aurora_replication_lag,
    aws_cloudwatch_metric_alarm.efs_replication_lag,
  ]
}
