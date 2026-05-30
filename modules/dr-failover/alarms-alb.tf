###############################
## Tier-1 alarms: ALB layer   ##
###############################
# Two alarms on the prod ALB in eu-west-1:
#
#   1. UnHealthyHostCount > 0     — no healthy backend targets registered.
#                                   Catches "all pods crashed / no replicas /
#                                   network broken between ALB and targets."
#   2. HTTPCode_Target_5XX_Count  — sustained 5xx responses from backends.
#                                   Catches "pods up but app errors out."
#
# Both publish to dr-alerts (eu-west-1 topic).

# Look up the ALB by its tag-name to get the arn_suffix.
# This handles the auto-generated random suffix from AWS Load Balancer
# Controller — we only need the human name (set via Ingress annotation).
data "aws_lb" "prod" {
  provider = aws.source
  name     = var.prod_alb_name
}

#######################################################
# Alarm 1: HealthyHostCount across all target groups  #
# (using UnHealthyHostCount is more reliable than     #
#  HealthyHostCount when targets aren't registered)   #
#######################################################
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  provider = aws.source

  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  alarm_description   = "Prod ALB has unhealthy backend targets. Catches pod-level / target-registration failures invisible to the app-level /health probe."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_unhealthy_evaluation_periods
  datapoints_to_alarm = var.alb_unhealthy_datapoints_to_alarm
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_unhealthy_period_seconds
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.prod.arn_suffix
  }

  alarm_actions = [aws_sns_topic.dr_alerts_source.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_source.arn]

  tags = var.tags
}

##########################################################
# Alarm 2: HTTP 5xx FROM TARGETS (backend errors, not    #
# ALB errors) — catches "app is erroring out" condition. #
##########################################################
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  provider = aws.source

  alarm_name          = "${var.name_prefix}-alb-target-5xx-high"
  alarm_description   = "Prod ALB backends returning 5xx at elevated rate. App-level error signal."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  datapoints_to_alarm = var.alb_5xx_datapoints_to_alarm
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.prod.arn_suffix
  }

  alarm_actions = [aws_sns_topic.dr_alerts_source.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_source.arn]

  tags = var.tags
}
