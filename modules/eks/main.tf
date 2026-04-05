provider "helm" {
  kubernetes {
    host = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(
      aws_eks_cluster.this.certificate_authority[0].data
    )
    token = aws_eks_cluster.this.identity[0].oidc[0].issuer != "" ? null : null
  }
}

###############################
## IAM role – EKS control plane  ##
###############################
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


###############################
## KMS key – secrets encryption ##
###############################
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  tags              = var.tags
}

###############################
## EKS cluster ##
###############################
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34"

  deletion_protection = true

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids              = var.private_app_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = var.tags
}

###############################
## IAM role – worker nodes ##
###############################
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset(concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ], var.enable_cloudwatch_observability ? [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ] : []))

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

###############################
## Managed Node Group ##
###############################
resource "aws_launch_template" "core_ng" {
  name = "${var.cluster_name}-core-ng"

  user_data = base64encode(<<-EOT
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==EKS_BOUNDARY=="

    --==EKS_BOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash
    if [ -x /etc/eks/bootstrap.sh ]; then
      /etc/eks/bootstrap.sh ${aws_eks_cluster.this.name} --use-max-pods false --kubelet-extra-args '--max-pods=${var.core_node_max_pods} --kube-reserved=cpu=200m,memory=512Mi --system-reserved=cpu=200m,memory=512Mi'
    fi

    --==EKS_BOUNDARY==--
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

resource "aws_eks_node_group" "core" {
  for_each = {
    for idx, subnet_id in var.private_app_subnet_ids :
    format("%02d", idx + 1) => subnet_id
  }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "core-ng-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value]

  instance_types = ["m6i.xlarge"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = 1
    desired_size = 1
    max_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  node_repair_config {
    enabled = true
  }

  labels = {
    role = "core"
  }

  launch_template {
    id      = aws_launch_template.core_ng.id
    version = aws_launch_template.core_ng.latest_version
  }

  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  tags = merge(var.tags, {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  })
}

resource "aws_eks_node_group" "github_runners_spot" {
  count = var.enable_spot_runner_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "github-runners-spot-ng"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_app_subnet_ids

  instance_types = var.spot_runner_instance_types
  capacity_type  = "SPOT"

  scaling_config {
    min_size     = var.spot_runner_min_size
    desired_size = var.spot_runner_desired_size
    max_size     = var.spot_runner_max_size
  }

  update_config {
    max_unavailable = 1
  }

  node_repair_config {
    enabled = true
  }

  labels = {
    role      = "github-runners-spot"
    lifecycle = "spot"
  }

  taint {
    key    = var.spot_runner_taint_key
    value  = var.spot_runner_taint_value
    effect = "NO_SCHEDULE"
  }

  launch_template {
    id      = aws_launch_template.core_ng.id
    version = aws_launch_template.core_ng.latest_version
  }

  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  tags = merge(var.tags, {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  })
}

###############################
## EKS managed add-ons ##
###############################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = tostring(var.enable_prefix_delegation)
      WARM_PREFIX_TARGET       = tostring(var.warm_prefix_target)
    }
  })
  #addon_version = "v1.18.1-eksbuild.1"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  #addon_version = "v1.11.1-eksbuild.4"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
  #addon_version = "v1.29.0-eksbuild.1"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "amazon-cloudwatch-observability"
}

resource "aws_eks_addon" "metrics_server" {
  count = var.enable_metrics_server_addon ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "metrics-server"
  addon_version = trimspace(var.metrics_server_addon_version) != "" ? trimspace(var.metrics_server_addon_version) : null
}

resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

###############################
## EFS + EFS CSI ##
###############################
resource "aws_security_group" "efs" {
  count = var.enable_efs_csi_driver ? 1 : 0

  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS mounts from EKS workloads"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from EKS cluster security group"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  }

  ingress {
    description     = "NFS from private app security group"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.private_app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efs-sg"
  })
}

resource "aws_efs_file_system" "this" {
  count = var.enable_efs_csi_driver ? 1 : 0

  encrypted        = var.efs_encrypted
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = var.enable_efs_csi_driver ? toset(var.private_app_subnet_ids) : toset([])

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs[0].id]
}

resource "aws_iam_role" "efs_csi" {
  count = var.enable_efs_csi_driver ? 1 : 0

  name = "${var.cluster_name}-efs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  count = var.enable_efs_csi_driver ? 1 : 0

  role       = aws_iam_role.efs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_eks_addon" "efs_csi" {
  count = var.enable_efs_csi_driver ? 1 : 0

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-efs-csi-driver"
  service_account_role_arn = aws_iam_role.efs_csi[0].arn

  depends_on = [
    aws_iam_role_policy_attachment.efs_csi
  ]
}

resource "aws_efs_backup_policy" "this" {
  count = var.enable_efs_csi_driver && var.enable_efs_backup ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = "ENABLED"
  }
}


###############################
## ALB Controller ##
###############################


resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da0afd40b88"
  ]
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/iam/alb-controller-policy.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}


###############################
## Allow EKS API from private_app
###############################
resource "aws_security_group_rule" "eks_api_from_private_app" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = var.private_app_sg_id
}


###############################
## EKS Admin permission ##
###############################


resource "aws_eks_access_entry" "admin_role" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = "arn:aws:iam::495711089104:role/dev-vpc-ec2-ssm-role"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_role" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin_role.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
