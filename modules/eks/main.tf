# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.this.endpoint
#     cluster_ca_certificate = base64decode(
#       aws_eks_cluster.this.certificate_authority[0].data
#     )
#     token = aws_eks_cluster.this.identity[0].oidc[0].issuer != "" ? null : null
#   }
# }

# ###############################
# ## IAM role – EKS control plane  ##
# ###############################
# resource "aws_iam_role" "eks_cluster" {
#   name = "${var.cluster_name}-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   role       = aws_iam_role.eks_cluster.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = aws_iam_role.eks_nodes.arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = [
#           "system:bootstrappers",
#           "system:nodes"
#         ]
#       }
#     ])
#   }

#   depends_on = [
#     aws_eks_node_group.core
#   ]
# }

# ###############################
# ## KMS key – secrets encryption ##
# ###############################
# resource "aws_kms_key" "eks" {
#   description             = "KMS key for EKS secrets"
#   enable_key_rotation     = true
#   deletion_window_in_days = 30
#   tags                    = var.tags
# }

# resource "aws_kms_alias" "eks" {
#   name          = "alias/${var.cluster_name}-eks"
#   target_key_id = aws_kms_key.eks.key_id
# }

# ###############################
# ## EKS cluster ##
# ###############################
# resource "aws_eks_cluster" "this" {
#   name     = var.cluster_name
#   role_arn = aws_iam_role.eks_cluster.arn
#   version  = "1.32"

#   vpc_config {
#     subnet_ids              = var.private_app_subnet_ids
#     endpoint_private_access = true
#     endpoint_public_access  = false
#   }

#   encryption_config {
#     resources = ["secrets"]
#     provider {
#       key_arn = aws_kms_key.eks.arn
#     }
#   }

#   enabled_cluster_log_types = [
#     "api",
#     "audit",
#     "authenticator",
#     "controllerManager",
#     "scheduler"
#   ]

#   tags = var.tags
# }

# ###############################
# ## IAM role – worker nodes ##
# ###############################
# resource "aws_iam_role" "eks_nodes" {
#   name = "${var.cluster_name}-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "node_policies" {
#   for_each = toset([
#     "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#     "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   ])

#   role       = aws_iam_role.eks_nodes.name
#   policy_arn = each.value
# }

# ###############################
# ## Managed Node Group ##
# ###############################
# resource "aws_eks_node_group" "core" {
#   cluster_name    = aws_eks_cluster.this.name
#   node_group_name = "core-ng"
#   node_role_arn  = aws_iam_role.eks_nodes.arn
#   subnet_ids     = var.private_app_subnet_ids

#   instance_types = ["m6i.large"]
#   capacity_type  = "ON_DEMAND"

#   scaling_config {
#     min_size     = 3   # one per AZ
#     desired_size = 3
#     max_size     = 6
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   labels = {
#     role = "core"
#   }

#   tags = var.tags
# }

# ###############################
# ## EKS managed add-ons ##
# ###############################
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name  = aws_eks_cluster.this.name
#   addon_name    = "vpc-cni"
#   addon_version = "v1.18.1-eksbuild.1"
# }

# resource "aws_eks_addon" "coredns" {
#   cluster_name  = aws_eks_cluster.this.name
#   addon_name    = "coredns"
#   addon_version = "v1.11.1-eksbuild.4"
# }

# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name  = aws_eks_cluster.this.name
#   addon_name    = "kube-proxy"
#   addon_version = "v1.29.0-eksbuild.1"
# }


# resource "aws_iam_role" "ebs_csi" {
#   name = "${var.cluster_name}-ebs-csi"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
#         }
#       }
#     }]
#   })
# }

# resource "aws_eks_addon" "ebs_csi" {
#   cluster_name             = aws_eks_cluster.this.name
#   addon_name               = "aws-ebs-csi-driver"
#   service_account_role_arn = aws_iam_role.ebs_csi.arn
# }

# resource "aws_iam_role_policy_attachment" "ebs_csi" {
#   role       = aws_iam_role.ebs_csi.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }


# ###############################
# ## ALB Controller ##
# ###############################

# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.this.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
# }

# resource "aws_iam_policy" "alb_controller" {
#   name        = "${var.cluster_name}-alb-controller"
#   description = "IAM policy for AWS Load Balancer Controller"

#   policy = file("${path.module}/iam/alb-controller-policy.json")
# }

# resource "aws_iam_role" "alb_controller" {
#   name = "${var.cluster_name}-alb-controller"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.eks.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "alb_attach" {
#   role       = aws_iam_role.alb_controller.name
#   policy_arn = aws_iam_policy.alb_controller.arn
# }

# resource "kubernetes_config_map_v1" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = aws_iam_role.eks_nodes.arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = [
#           "system:bootstrappers",
#           "system:nodes"
#         ]
#       }
#     ])
#   }

#   depends_on = [
#     aws_eks_node_group.core
#   ]
# }


# ###############################
# ## Metric Server ##
# ###############################

# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   namespace  = "kube-system"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   chart      = "metrics-server"
#   version    = "3.12.1"

#   values = [yamlencode({
#     args = [
#       "--kubelet-insecure-tls",   
#       "--kubelet-preferred-address-types=InternalIP"
#     ]
#   })]
# }

# ###############################
# ## EKS Admin permission ##
# ###############################

# # variable "admin_role_arn" {
# #   type        = string
# #   description = "IAM role with EKS admin access"
# # }

# # resource "aws_eks_access_entry" "admin" {
# #   cluster_name  = aws_eks_cluster.this.name
# #   principal_arn = var.admin_role_arn
# #   type          = "STANDARD"
# # }

# # resource "aws_eks_access_policy_association" "admin" {
# #   cluster_name  = aws_eks_cluster.this.name
# #   principal_arn = var.admin_role_arn
# #   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

# #   access_scope {
# #     type = "cluster"
# #   }
# # }


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
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

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_nodes.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_node_group.core
  ]
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

###############################
## EKS cluster ##
###############################
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.32"

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
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

###############################
## Managed Node Group ##
###############################
resource "aws_eks_node_group" "core" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "core-ng"
  node_role_arn  = aws_iam_role.eks_nodes.arn
  subnet_ids     = var.private_app_subnet_ids

  instance_types = ["m6i.large"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = 3   # one per AZ
    desired_size = 3
    max_size     = 6
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "core"
  }

  tags = var.tags
}

###############################
## EKS managed add-ons ##
###############################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  #addon_version = "v1.18.1-eksbuild.1"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  #addon_version = "v1.11.1-eksbuild.4"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  #addon_version = "v1.29.0-eksbuild.1"
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
## Metric Server ##
###############################

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"

  values = [yamlencode({
    args = [
      "--kubelet-insecure-tls",   
      "--kubelet-preferred-address-types=InternalIP"
    ]
  })]
}

###############################
## Allow EKS API from private_app
###############################
resource "aws_security_group_rule" "eks_api_from_private_app" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id         = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = var.private_app_sg_id
}


###############################
## EKS Admin permission ##
###############################

# variable "admin_role_arn" {
#   type        = string
#   description = "IAM role with EKS admin access"
# }

# resource "aws_eks_access_entry" "admin" {
#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = var.admin_role_arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "admin" {
#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = var.admin_role_arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#   access_scope {
#     type = "cluster"
#   }
# }
