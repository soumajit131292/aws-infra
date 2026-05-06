locals {
  db_credentials = var.db_credentials_secret_name != "" ? jsondecode(data.aws_secretsmanager_secret_version.db_credentials[0].secret_string) : {}

  resolved_master_username = var.db_credentials_secret_name != "" ? try(local.db_credentials.username, null) : var.master_username
  resolved_master_password = var.db_credentials_secret_name != "" ? try(local.db_credentials.password, null) : var.master_password
  kms_key_id_effective     = var.create_rds_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_id
}

resource "aws_kms_key" "rds" {
  count = var.create_rds_kms_key ? 1 : 0

  description             = "KMS key for Aurora ${var.cluster_identifier}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-kms"
  })
}

resource "aws_kms_alias" "rds" {
  count = var.create_rds_kms_key ? 1 : 0

  name          = "alias/${var.rds_kms_key_alias}"
  target_key_id = aws_kms_key.rds[0].key_id
}

resource "aws_cloudwatch_log_group" "aurora_postgresql" {
  name              = "/aws/rds/cluster/${var.cluster_identifier}/postgresql"
  retention_in_days = var.cloudwatch_log_retention_in_days

  tags = var.tags
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
  allowed_cidr_blocks               = var.allowed_cidr_blocks
  port                              = var.port
  backup_retention_period           = var.backup_retention_period
  preferred_backup_window           = var.preferred_backup_window
  preferred_maintenance_window      = var.preferred_maintenance_window
  deletion_protection               = var.deletion_protection
  skip_final_snapshot               = var.skip_final_snapshot
  final_snapshot_identifier         = var.final_snapshot_identifier
  apply_immediately                 = var.apply_immediately
  storage_encrypted                 = var.storage_encrypted
  kms_key_id                        = local.kms_key_id_effective
  copy_tags_to_snapshot             = var.copy_tags_to_snapshot
  enabled_cloudwatch_logs_exports   = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled      = var.performance_insights_enabled
  enhanced_monitoring_interval      = var.enhanced_monitoring_interval
  enhanced_monitoring_role_arn      = var.enhanced_monitoring_role_arn
  auto_minor_version_upgrade        = var.auto_minor_version_upgrade
  enable_rds_proxy                  = var.enable_rds_proxy
  rds_proxy_name                    = var.rds_proxy_name
  rds_proxy_secret_arn              = trimspace(var.rds_proxy_secret_arn) != "" ? trimspace(var.rds_proxy_secret_arn) : (var.db_credentials_secret_name != "" ? data.aws_secretsmanager_secret.db_credentials[0].arn : "")
  rds_proxy_subnet_ids              = length(var.rds_proxy_subnet_ids) > 0 ? var.rds_proxy_subnet_ids : data.terraform_remote_state.vpc.outputs.private_app_subnet_ids
  rds_proxy_iam_auth                = var.rds_proxy_iam_auth
  enforce_rds_proxy_only            = var.enforce_rds_proxy_only
  rds_proxy_max_connections_percent = var.rds_proxy_max_connections_percent
  tags                              = var.tags

  depends_on = [
    aws_cloudwatch_log_group.aurora_postgresql
  ]
}
