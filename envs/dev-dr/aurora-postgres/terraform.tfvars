region                          = "us-west-1"
cluster_identifier              = "dev-aurora-postgres"
database_name                   = "accesshub"
db_credentials_secret_name      = "dev/aurora/app-credentials"
engine_version                  = "16.4"
instance_class                  = "db.t4g.medium"
instance_count                  = 1
backup_retention_period         = 1
preferred_backup_window         = "03:00-04:00"
preferred_maintenance_window    = "sun:04:00-sun:05:00"
port                            = 5432
deletion_protection             = false
skip_final_snapshot             = false
final_snapshot_identifier       = "dev-aurora-postgres-final"
apply_immediately               = true
storage_encrypted               = true
copy_tags_to_snapshot           = true
enabled_cloudwatch_logs_exports = ["postgresql"]
performance_insights_enabled    = false
auto_minor_version_upgrade      = true

allowed_cidr_blocks = []

tags = {
  env   = "dev"
  owner = "terraform-accesshub-platform"
}
