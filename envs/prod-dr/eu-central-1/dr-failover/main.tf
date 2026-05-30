module "dr_failover" {
  source = "../../../../modules/dr-failover"

  providers = {
    aws           = aws
    aws.source    = aws.source
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix   = var.name_prefix
  source_region = var.source_region
  dr_region     = var.dr_region

  # Aurora
  global_cluster_id = data.terraform_remote_state.aurora_global.outputs.global_cluster_identifier
  dr_cluster_arn    = data.terraform_remote_state.prod_dr_aurora.outputs.cluster_arn

  # EFS
  source_efs_id = data.terraform_remote_state.prod_eks.outputs.efs_file_system_id
  dr_efs_id     = data.terraform_remote_state.efs_replication.outputs.destination_file_system_id

  # EKS
  dr_eks_cluster_name   = data.terraform_remote_state.prod_dr_eks.outputs.cluster_name
  dr_eks_nodegroup_name = "core-ng" # update if your prod-dr nodegroup is named differently
  target_node_desired   = var.target_node_desired
  target_node_max       = var.target_node_max
  target_app_replicas   = var.target_app_replicas

  # Private DNS (preflight reads this; no longer used for DNS flipping)
  dr_private_hosted_zone_id = data.terraform_remote_state.prod_dr_route53.outputs.hosted_zone_id

  # Public health check + validation
  public_health_check_endpoint = var.public_health_check_endpoint
  public_health_check_url      = var.public_health_check_url
  r53_dr_health_check_id       = var.r53_dr_health_check_id

  # Tier-1 alarms: ALB
  prod_alb_name     = var.prod_alb_name
  alb_5xx_threshold = var.alb_5xx_threshold

  # Tier-1 alarms: Aurora
  prod_cluster_identifier             = var.prod_cluster_identifier
  dr_cluster_identifier               = var.dr_cluster_identifier
  aurora_replication_lag_threshold_ms = var.aurora_replication_lag_threshold_ms
  aurora_min_connections              = var.aurora_min_connections

  # Tier-1 alarms: EFS
  efs_replication_lag_threshold_sec = var.efs_replication_lag_threshold_sec

  # Phase 1 — eval-window + M-of-N tuning
  cw_alarm_evaluation_periods                = var.cw_alarm_evaluation_periods
  cw_alarm_datapoints_to_alarm               = var.cw_alarm_datapoints_to_alarm
  alb_unhealthy_evaluation_periods           = var.alb_unhealthy_evaluation_periods
  alb_unhealthy_datapoints_to_alarm          = var.alb_unhealthy_datapoints_to_alarm
  alb_5xx_evaluation_periods                 = var.alb_5xx_evaluation_periods
  alb_5xx_datapoints_to_alarm                = var.alb_5xx_datapoints_to_alarm
  aurora_replication_lag_evaluation_periods  = var.aurora_replication_lag_evaluation_periods
  aurora_replication_lag_datapoints_to_alarm = var.aurora_replication_lag_datapoints_to_alarm
  aurora_no_connections_evaluation_periods   = var.aurora_no_connections_evaluation_periods
  aurora_no_connections_datapoints_to_alarm  = var.aurora_no_connections_datapoints_to_alarm
  aurora_db_load_threshold                   = var.aurora_db_load_threshold
  aurora_db_load_evaluation_periods          = var.aurora_db_load_evaluation_periods
  aurora_db_load_datapoints_to_alarm         = var.aurora_db_load_datapoints_to_alarm
  efs_replication_lag_evaluation_periods     = var.efs_replication_lag_evaluation_periods
  efs_replication_lag_datapoints_to_alarm    = var.efs_replication_lag_datapoints_to_alarm

  # Phase 2: alarm suppression
  argocd_webhook_secret             = trimspace(data.aws_secretsmanager_secret_version.argocd_webhook_secret.secret_string)
  alarm_suppression_max_age_seconds = var.alarm_suppression_max_age_seconds

  # Approval
  approval_shared_secret   = trimspace(data.aws_secretsmanager_secret_version.approval_shared_secret.secret_string)
  approval_timeout_seconds = var.approval_timeout_seconds

  # GitHub
  github_pat_secret_arn = var.github_pat_secret_arn
  github_owner          = var.github_owner
  github_repo           = var.github_repo
  github_branch         = var.github_branch
  github_values_path    = var.github_values_path

  # Subscribers (email-only)
  alert_email_subscribers = var.alert_email_subscribers

  tags = var.tags
}
