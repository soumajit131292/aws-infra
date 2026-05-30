###############################
## Detection: Route 53 probe  ##
###############################
# Route 53 public health check on the prod ALB hostname.
# CloudWatch alarm in us-east-1 (HealthCheckStatus metrics only publish there).
# Alarm publishes to the dr-alerts SNS topic in us-east-1 (same region required).

resource "aws_route53_health_check" "prod_app" {
  fqdn              = var.public_health_check_endpoint
  type              = "HTTPS"
  resource_path     = "/health"
  port              = 443
  request_interval  = 30
  failure_threshold = 3
  measure_latency   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prod-app-healthcheck"
  })
}

resource "aws_cloudwatch_metric_alarm" "prod_app_unhealthy" {
  provider = aws.us_east_1

  alarm_name          = "${var.name_prefix}-route53-prod-app-unhealthy"
  alarm_description   = "Prod ALB /health is returning unhealthy from Route 53 global checkers. External-perspective signal — possible regional outage."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cw_alarm_evaluation_periods
  datapoints_to_alarm = var.cw_alarm_datapoints_to_alarm
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = var.cw_alarm_period_seconds
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.prod_app.id
  }

  alarm_actions = [aws_sns_topic.dr_alerts_us_east_1.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_us_east_1.arn]

  tags = var.tags
}
