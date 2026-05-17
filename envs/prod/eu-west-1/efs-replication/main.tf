###############################
## Destination KMS CMK       ##
###############################
resource "aws_kms_key" "dr_efs" {
  provider                = aws.dr
  description             = "${var.destination_efs_name_tag} CMK for replicated EFS"
  deletion_window_in_days = var.destination_kms_deletion_window_in_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowEFSServiceUse"
        Effect    = "Allow"
        Principal = { Service = "elasticfilesystem.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.destination_efs_name_tag}-kms"
  })
}

resource "aws_kms_alias" "dr_efs" {
  provider      = aws.dr
  name          = var.destination_kms_key_alias
  target_key_id = aws_kms_key.dr_efs.key_id
}

###############################
## Replication primitive     ##
###############################
module "efs_replication" {
  source = "../../../../modules/efs-replication"

  source_file_system_id   = local.source_efs_id
  destination_region      = var.destination_region
  destination_kms_key_arn = aws_kms_key.dr_efs.arn
  # Leave destination_availability_zone_name null for Regional EFS in destination.
}

###############################
## Destination EFS SG        ##
###############################
resource "aws_security_group" "destination_efs" {
  provider = aws.dr

  name        = "${var.destination_efs_name_tag}-sg"
  description = "EFS mount-target SG in prod-dr for the replicated EFS"
  vpc_id      = local.dr_vpc_id

  ingress {
    description     = "NFS from prod-dr EKS cluster SG"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [local.dr_eks_cluster_sg_id]
  }

  ingress {
    description     = "NFS from prod-dr private app SG"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [local.dr_private_app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.destination_efs_name_tag}-sg"
  })
}

###############################
## Destination Mount Targets ##
###############################
resource "aws_efs_mount_target" "destination" {
  for_each = toset(local.dr_private_app_subnet_ids)

  provider = aws.dr

  file_system_id  = module.efs_replication.destination_file_system_id
  subnet_id       = each.value
  security_groups = [aws_security_group.destination_efs.id]
}
