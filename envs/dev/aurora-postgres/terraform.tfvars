region                          = "us-east-1"
cluster_identifier              = "dev-aurora-postgres"
database_name                   = "accesshub"
db_credentials_secret_name      = "dev/aurora/app-credentials"
engine_version                  = "16.4"
instance_class                  = "db.t4g.medium"
instance_count                  = 2
backup_retention_period         = 7
preferred_backup_window         = "03:00-04:00"
preferred_maintenance_window    = "sun:04:00-sun:05:00"
port                            = 5432
deletion_protection             = false
skip_final_snapshot             = false
final_snapshot_identifier       = "dev-aurora-postgres-final"
apply_immediately               = true
storage_encrypted               = true
create_rds_kms_key              = true
rds_kms_key_alias               = "dev-aurora-postgres"
copy_tags_to_snapshot           = true
enabled_cloudwatch_logs_exports = ["postgresql"]
performance_insights_enabled    = true
enhanced_monitoring_interval    = 60
auto_minor_version_upgrade      = true

enable_rds_proxy                  = true
rds_proxy_name                    = "dev-aurora-postgres-proxy"
rds_proxy_iam_auth                = "DISABLED"
enforce_rds_proxy_only            = true
rds_proxy_max_connections_percent = 80

allowed_cidr_blocks = []

tags = {
  env   = "dev"
  owner = "terraform-accesshub-platform"
}
