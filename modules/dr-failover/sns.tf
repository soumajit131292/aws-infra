###############################
## SNS topics                 ##
###############################
#
# Three topic FAMILIES, each replicated across the regions where alarms live:
#
#   dr-alerts    -- detection layer fires here; pages on-call.
#                   Topics in: eu-central-1 (default), eu-west-1, us-east-1.
#                   Reason for multi-region: CloudWatch alarms can only
#                   publish to SNS topics in the SAME region.
#
#   dr-approval  -- Step Functions sends approval-request messages here.
#                   Topic in: eu-central-1 (where the state machine lives).
#
#   dr-complete  -- Step Functions sends completion messages here.
#                   Topic in: eu-central-1.
#
# The same email subscriber list is attached to ALL three dr-alerts
# topics, so on-call gets one notification regardless of which region's
# alarm fired.

#############################################
# dr-alerts topic — eu-central-1 (default)  #
#############################################
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.name_prefix}-dr-alerts"
  tags = merge(var.tags, { Purpose = "DR detection alerts eu-central-1" })
}

resource "aws_sns_topic_subscription" "alerts_email" {
  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

##########################################
# dr-alerts topic — eu-west-1 (source)   #
##########################################
resource "aws_sns_topic" "dr_alerts_source" {
  provider = aws.source

  name = "${var.name_prefix}-dr-alerts"
  tags = merge(var.tags, { Purpose = "DR detection alerts eu-west-1" })
}

resource "aws_sns_topic_subscription" "alerts_email_source" {
  provider = aws.source

  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.dr_alerts_source.arn
  protocol  = "email"
  endpoint  = each.value
}

#######################################
# dr-alerts topic — us-east-1         #
#######################################
resource "aws_sns_topic" "dr_alerts_us_east_1" {
  provider = aws.us_east_1

  name = "${var.name_prefix}-dr-alerts"
  tags = merge(var.tags, { Purpose = "DR detection alerts us-east-1 for Route53 metrics" })
}

resource "aws_sns_topic_subscription" "alerts_email_us_east_1" {
  provider = aws.us_east_1

  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.dr_alerts_us_east_1.arn
  protocol  = "email"
  endpoint  = each.value
}

#######################################
# dr-approval topic (eu-central-1)    #
#######################################
resource "aws_sns_topic" "dr_approval" {
  name = "${var.name_prefix}-dr-approval"
  tags = merge(var.tags, { Purpose = "DR approval requests" })
}

resource "aws_sns_topic_subscription" "approval_email" {
  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.dr_approval.arn
  protocol  = "email"
  endpoint  = each.value
}

#######################################
# dr-complete topic (eu-central-1)    #
#######################################
resource "aws_sns_topic" "dr_complete" {
  name = "${var.name_prefix}-dr-complete"
  tags = merge(var.tags, { Purpose = "DR completion notifications" })
}

resource "aws_sns_topic_subscription" "complete_email" {
  for_each  = toset(var.alert_email_subscribers)
  topic_arn = aws_sns_topic.dr_complete.arn
  protocol  = "email"
  endpoint  = each.value
}
