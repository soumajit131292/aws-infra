###############################################
## DR oncall dashboard — one pane of glass    ##
###############################################
# Single CloudWatch dashboard that aggregates every signal an oncall
# engineer needs at 3am during a suspected regional incident.
#
# Layout (24-column grid):
#   Row 1: Alarm status tiles (all 7 Tier-1 alarms + Step Functions executions)
#   Row 2: External-perspective + ALB health (eu-west-1 + us-east-1)
#   Row 3: Aurora signals (replication lag, connections, DBLoad)
#   Row 4: EFS replication signal + DR EKS state
#   Row 5: Step Functions log tail + alarm-suppression state
#
# Dashboards are created in a single region (eu-central-1 here) but each
# widget can specify its own `region` property to pull metrics from
# eu-west-1, eu-central-1, or us-east-1. The console renders all three
# transparently in one page.

resource "aws_cloudwatch_dashboard" "dr_overview" {
  dashboard_name = "${var.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      ####################################################
      # ROW 1 — Alarm status tiles (single source of truth)
      ####################################################
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 4
        properties = {
          title = "Tier-1 DR Detection Alarms"
          alarms = compact([
            aws_cloudwatch_metric_alarm.prod_app_unhealthy.arn,
            aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn,
            aws_cloudwatch_metric_alarm.alb_target_5xx.arn,
            aws_cloudwatch_metric_alarm.aurora_replication_lag.arn,
            aws_cloudwatch_metric_alarm.aurora_db_load_high.arn,
            try(aws_cloudwatch_metric_alarm.aurora_no_connections[0].arn, ""),
            aws_cloudwatch_metric_alarm.efs_replication_lag.arn,
          ])
        }
      },

      ####################################################
      # ROW 2 — External + ALB perspective
      ####################################################
      # Route 53 health-check status (us-east-1, external probes)
      {
        type   = "metric"
        x      = 0
        y      = 4
        width  = 8
        height = 6
        properties = {
          title  = "Route 53 health check — prod ALB (external view)"
          region = "us-east-1"
          view   = "timeSeries"
          stat   = "Minimum"
          period = 60
          yAxis  = { left = { min = 0, max = 1 } }
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", aws_route53_health_check.prod_app.id, { label = "1=healthy, 0=unhealthy" }]
          ]
          annotations = {
            horizontal = [{ value = 1, label = "healthy", color = "#2ca02c" }]
          }
        }
      },
      # ALB healthy / unhealthy hosts (eu-west-1)
      {
        type   = "metric"
        x      = 8
        y      = 4
        width  = 8
        height = 6
        properties = {
          title  = "Prod ALB targets — Healthy vs Unhealthy (eu-west-1)"
          region = var.source_region
          view   = "timeSeries"
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", data.aws_lb.prod.arn_suffix, { label = "Healthy" }],
            [".", "UnHealthyHostCount", ".", ".", { label = "Unhealthy" }],
          ]
        }
      },
      # ALB 5XX errors (eu-west-1)
      {
        type   = "metric"
        x      = 16
        y      = 4
        width  = 8
        height = 6
        properties = {
          title  = "Prod ALB — 5XX errors per minute (eu-west-1)"
          region = var.source_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", data.aws_lb.prod.arn_suffix, { label = "Target 5XX" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { label = "ELB 5XX" }],
            [".", "RequestCount", ".", ".", { label = "Total requests", yAxis = "right" }],
          ]
          annotations = {
            horizontal = [{ value = var.alb_5xx_threshold, label = "alarm threshold", color = "#d62728" }]
          }
        }
      },

      ####################################################
      # ROW 3 — Aurora signals
      ####################################################
      # Replication lag (DR side, eu-central-1)
      {
        type   = "metric"
        x      = 0
        y      = 10
        width  = 8
        height = 6
        properties = {
          title  = "Aurora Global DB — replication lag (eu-central-1)"
          region = var.dr_region
          view   = "timeSeries"
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/RDS", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", var.dr_cluster_identifier, { label = "Lag (ms)" }]
          ]
          annotations = {
            horizontal = [{ value = var.aurora_replication_lag_threshold_ms, label = "alarm threshold", color = "#d62728" }]
          }
        }
      },
      # DatabaseConnections — prod cluster (eu-west-1)
      {
        type   = "metric"
        x      = 8
        y      = 10
        width  = 8
        height = 6
        properties = {
          title  = "Aurora prod cluster — DatabaseConnections (eu-west-1)"
          region = var.source_region
          view   = "timeSeries"
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.prod_cluster_identifier, { label = "Connections" }]
          ]
          annotations = {
            horizontal = [{ value = var.aurora_min_connections, label = "alarm floor", color = "#d62728" }]
          }
        }
      },
      # DBLoad (AAS) — prod cluster (eu-west-1)
      {
        type   = "metric"
        x      = 16
        y      = 10
        width  = 8
        height = 6
        properties = {
          title  = "Aurora prod cluster — DBLoad / vCPUs (eu-west-1)"
          region = var.source_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/RDS", "DBLoad", "DBClusterIdentifier", var.prod_cluster_identifier, { label = "Active sessions" }]
          ]
          annotations = {
            horizontal = [{ value = var.aurora_db_load_threshold, label = "alarm threshold", color = "#d62728" }]
          }
        }
      },

      ####################################################
      # ROW 4 — EFS replication + Step Functions executions
      ####################################################
      # EFS TimeSinceLastSync (DR-side destination filesystem)
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 12
        height = 6
        properties = {
          title  = "EFS replication — TimeSinceLastSync (DR filesystem, eu-central-1)"
          region = var.dr_region
          view   = "timeSeries"
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/EFS", "TimeSinceLastSync", "FileSystemId", var.dr_efs_id, { label = "Seconds since last sync" }]
          ]
          annotations = {
            horizontal = [{ value = var.efs_replication_lag_threshold_sec, label = "alarm threshold", color = "#d62728" }]
          }
        }
      },
      # Step Functions executions (started / succeeded / failed)
      {
        type   = "metric"
        x      = 12
        y      = 16
        width  = 12
        height = 6
        properties = {
          title  = "DR Step Functions — executions (eu-central-1)"
          region = var.dr_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineArn", aws_sfn_state_machine.dr_failover.arn, { label = "Started" }],
            [".", "ExecutionsSucceeded", ".", ".", { label = "Succeeded", color = "#2ca02c" }],
            [".", "ExecutionsFailed", ".", ".", { label = "Failed", color = "#d62728" }],
            [".", "ExecutionsTimedOut", ".", ".", { label = "TimedOut", color = "#ff7f0e" }],
            [".", "ExecutionsAborted", ".", ".", { label = "Aborted" }],
          ]
        }
      },

      ####################################################
      # ROW 5 — Step Functions log tail + alarm suppression
      ####################################################
      # Recent Step Functions log entries (last 1h)
      {
        type   = "log"
        x      = 0
        y      = 22
        width  = 16
        height = 6
        properties = {
          title  = "DR Step Functions — recent execution events (last 1h)"
          region = var.dr_region
          query  = "SOURCE '${aws_cloudwatch_log_group.sfn.name}' | fields @timestamp, type, details.name | sort @timestamp desc | limit 50"
          view   = "table"
        }
      },
      # Alarm-actions-controller invocations (Phase 2 deploy suppression)
      {
        type   = "metric"
        x      = 16
        y      = 22
        width  = 8
        height = 6
        properties = {
          title  = "Alarm suppression Lambda — invocations (eu-central-1)"
          region = var.dr_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.alarm_actions_controller.function_name, { label = "Invocations" }],
            [".", "Errors", ".", ".", { label = "Errors", color = "#d62728" }],
          ]
        }
      },
    ]
  })
}
