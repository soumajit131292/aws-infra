#############################################
# CloudWatch monitoring + alerts for the dev Aurora cluster.
# Read I/O + CPUUtilization + FreeLocalStorage alarms per instance, emailing
# alert_email_subscribers (reused from the dr-failover list).
#############################################
module "rds_alarms" {
  source = "../../../modules/rds-alarms"

  name_prefix             = "dev"
  db_instance_identifiers = tolist(data.aws_rds_cluster.this.cluster_members)
  alert_email_subscribers = var.alert_email_subscribers

  tags = var.tags
}
