region                           = "eu-central-1"
cluster_identifier               = "prod-dr-aurora-postgres"
cloudwatch_log_retention_in_days = 365 # CEEL: 365-day log retention
database_name                    = "accesshub"
db_credentials_secret_name       = "prod-dr/aurora/app-credentials"

# Must match the primary cluster exactly. Aurora Global Database
# requires identical engine + version across primary and all secondaries.
engine_version = "16.4"
instance_class = "db.r6g.large"
instance_count = 2

backup_retention_period      = 7
preferred_backup_window      = "03:00-04:00"
preferred_maintenance_window = "sun:04:00-sun:05:00"
port                         = 5432

deletion_protection       = true
skip_final_snapshot       = false
final_snapshot_identifier = "prod-dr-aurora-postgres-final"
apply_immediately         = true

storage_encrypted     = true
create_rds_kms_key    = true
rds_kms_key_alias     = "prod-dr-aurora-postgres"
copy_tags_to_snapshot = true

enabled_cloudwatch_logs_exports = ["postgresql"]
performance_insights_enabled    = true
enhanced_monitoring_interval    = 60
auto_minor_version_upgrade      = true

enable_rds_proxy                  = true
rds_proxy_name                    = "prod-dr-aurora-postgres-proxy"
rds_proxy_iam_auth                = "DISABLED"
enforce_rds_proxy_only            = true
rds_proxy_max_connections_percent = 80

allowed_cidr_blocks = []

# Secondary mode -- cluster joins the Aurora Global Database created in prod.
# master_username / master_password / database_name are inherited from the
# primary cluster (eu-west-1) and ignored on this secondary.
is_secondary              = true
global_cluster_identifier = "prod-accesshub-global"

tags = {
  env   = "prod-dr"
  owner = "terraform-accesshub-platform"
}
