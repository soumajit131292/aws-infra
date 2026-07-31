#############################################
# CloudWatch monitoring + alerts for the PROD Aurora cluster.
# Read I/O + CPUUtilization + FreeLocalStorage alarms per instance, emailing
# alert_email_subscribers (reused from the dr-failover list).
# Thresholds are prod-appropriate (db.r6g.large) — tune to observed baseline.
#############################################
module "rds_alarms" {
  source = "../../../../modules/rds-alarms"

  name_prefix             = "prod"
  db_instance_identifiers = tolist(data.aws_rds_cluster.this.cluster_members)
  alert_email_subscribers = var.alert_email_subscribers

  cpu_utilization_threshold_percent  = var.cpu_utilization_threshold_percent
  read_iops_threshold                = var.read_iops_threshold
  read_throughput_threshold_bytes    = var.read_throughput_threshold_bytes
  free_local_storage_threshold_bytes = var.free_local_storage_threshold_bytes

  tags = var.tags
}
