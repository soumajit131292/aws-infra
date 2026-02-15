locals {
  db_credentials = var.db_credentials_secret_name != "" ? jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string) : {}

  resolved_master_username = var.db_credentials_secret_name != "" ? try(local.db_credentials.username, null) : var.master_username
  resolved_master_password = var.db_credentials_secret_name != "" ? try(local.db_credentials.password, null) : var.master_password
}

module "aurora_postgres" {
  source = "../../../modules/aurora-postgres"

  cluster_identifier = var.cluster_identifier
  database_name      = var.database_name
  master_username    = local.resolved_master_username
  master_password    = local.resolved_master_password
  engine_version     = var.engine_version
  instance_class     = var.instance_class
  instance_count     = var.instance_count
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  db_subnet_ids      = data.terraform_remote_state.vpc.outputs.private_db_subnet_ids
  allowed_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.private_app_sg_id,
    data.terraform_remote_state.eks.outputs.cluster_security_group_id,
  ]
  allowed_cidr_blocks             = var.allowed_cidr_blocks
  port                            = var.port
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  apply_immediately               = var.apply_immediately
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.performance_insights_enabled
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  tags                            = var.tags
}
