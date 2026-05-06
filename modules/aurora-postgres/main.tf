locals {
  final_snapshot_identifier              = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  rds_proxy_name                         = trimspace(var.rds_proxy_name) != "" ? trimspace(var.rds_proxy_name) : "${var.cluster_identifier}-proxy"
  rds_proxy_subnet_ids                   = length(var.rds_proxy_subnet_ids) > 0 ? var.rds_proxy_subnet_ids : var.db_subnet_ids
  enhanced_monitoring_role_arn_effective = trimspace(var.enhanced_monitoring_role_arn) != "" ? trimspace(var.enhanced_monitoring_role_arn) : try(aws_iam_role.rds_enhanced_monitoring[0].arn, null)
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-subnet-group"
  })
}

resource "aws_security_group" "aurora" {
  name        = "${var.cluster_identifier}-aurora-sg"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_rds_proxy && var.enforce_rds_proxy_only ? [] : var.allowed_security_group_ids

    content {
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "PostgreSQL from allowed security group"
    }
  }

  dynamic "ingress" {
    for_each = var.enable_rds_proxy && var.enforce_rds_proxy_only ? [] : var.allowed_cidr_blocks

    content {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "PostgreSQL from allowed CIDR"
    }
  }

  dynamic "ingress" {
    for_each = var.enable_rds_proxy ? [aws_security_group.rds_proxy[0].id] : []

    content {
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "PostgreSQL from RDS proxy security group"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-aurora-sg"
  })
}

resource "aws_security_group" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name        = "${local.rds_proxy_name}-sg"
  description = "Security group for RDS Proxy"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids

    content {
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "Proxy ingress from allowed security group"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks

    content {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Proxy ingress from allowed CIDR"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.rds_proxy_name}-sg"
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = var.cluster_identifier
  engine                          = "aurora-postgresql"
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  port                            = var.port
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = local.final_snapshot_identifier
  apply_immediately               = var.apply_immediately
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  lifecycle {
    precondition {
      condition     = var.skip_final_snapshot || length(var.final_snapshot_identifier) > 0
      error_message = "final_snapshot_identifier must be set when skip_final_snapshot is false"
    }
  }

  tags = merge(var.tags, {
    Name = var.cluster_identifier
  })
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier                   = "${var.cluster_identifier}-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  db_subnet_group_name         = aws_db_subnet_group.this.name
  publicly_accessible          = false
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.enhanced_monitoring_interval
  monitoring_role_arn          = var.enhanced_monitoring_interval > 0 ? local.enhanced_monitoring_role_arn_effective : null

  lifecycle {
    precondition {
      condition     = var.enhanced_monitoring_interval == 0 || local.enhanced_monitoring_role_arn_effective != null
      error_message = "enhanced_monitoring_interval > 0 requires enhanced_monitoring_role_arn or module-created enhanced monitoring role."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${count.index + 1}"
  })
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enhanced_monitoring_interval > 0 && length(trimspace(var.enhanced_monitoring_role_arn)) == 0 ? 1 : 0

  name = "${var.cluster_identifier}-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.enhanced_monitoring_interval > 0 && length(trimspace(var.enhanced_monitoring_role_arn)) == 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${local.rds_proxy_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${local.rds_proxy_name}-policy"
  role = aws_iam_role.rds_proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.rds_proxy_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_db_proxy" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = local.rds_proxy_name
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids         = local.rds_proxy_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_proxy[0].id]
  require_tls            = var.rds_proxy_require_tls
  idle_client_timeout    = var.rds_proxy_idle_client_timeout
  debug_logging          = var.rds_proxy_debug_logging

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.rds_proxy_secret_arn
    iam_auth    = var.rds_proxy_iam_auth
  }

  lifecycle {
    precondition {
      condition     = length(trimspace(var.rds_proxy_secret_arn)) > 0
      error_message = "rds_proxy_secret_arn must be set when enable_rds_proxy is true."
    }
  }

  tags = merge(var.tags, {
    Name = local.rds_proxy_name
  })
}

resource "aws_db_proxy_default_target_group" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    connection_borrow_timeout    = var.rds_proxy_connection_borrow_timeout
    max_connections_percent      = var.rds_proxy_max_connections_percent
    max_idle_connections_percent = var.rds_proxy_max_idle_connections_percent
  }
}

resource "aws_db_proxy_target" "cluster" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name         = aws_db_proxy.this[0].name
  target_group_name     = aws_db_proxy_default_target_group.this[0].name
  db_cluster_identifier = aws_rds_cluster.this.id
}
