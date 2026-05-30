###############################
## Lambda functions           ##
###############################
# Each Lambda packaged from its own directory under ./lambdas/.
# Each has its own least-privilege IAM role.
# Common configuration: Python 3.11, 256MB, 5-minute default timeout.

locals {
  lambda_runtime = "python3.11"
  lambda_memory  = 256

  lambdas = {
    preflight_checks = {
      timeout = 60
      env = {
        SOURCE_REGION             = var.source_region
        DR_REGION                 = var.dr_region
        GLOBAL_CLUSTER_ID         = var.global_cluster_id
        DR_CLUSTER_ARN            = var.dr_cluster_arn
        SOURCE_EFS_ID             = var.source_efs_id
        DR_EFS_ID                 = var.dr_efs_id
        DR_EKS_CLUSTER_NAME       = var.dr_eks_cluster_name
        DR_PRIVATE_HOSTED_ZONE_ID = var.dr_private_hosted_zone_id
        MAX_REPLICATION_LAG_SEC   = "60"
      }
    }
    aurora_failover = {
      timeout = 300
      env = {
        SOURCE_REGION        = var.source_region
        DR_REGION            = var.dr_region
        GLOBAL_CLUSTER_ID    = var.global_cluster_id
        DR_CLUSTER_ARN       = var.dr_cluster_arn
        POLL_TIMEOUT_SECONDS = "300"
      }
    }
    efs_promote = {
      timeout = 180
      env = {
        SOURCE_REGION        = var.source_region
        DR_REGION            = var.dr_region
        SOURCE_EFS_ID        = var.source_efs_id
        DR_EFS_ID            = var.dr_efs_id
        POLL_TIMEOUT_SECONDS = "180"
      }
    }
    eks_scale = {
      timeout = 600
      env = {
        DR_REGION             = var.dr_region
        DR_CLUSTER_NAME       = var.dr_eks_cluster_name
        DR_NODEGROUP_NAME     = var.dr_eks_nodegroup_name
        TARGET_NODE_DESIRED   = tostring(var.target_node_desired)
        TARGET_NODE_MAX       = tostring(var.target_node_max)
        GITHUB_PAT_SECRET_ARN = var.github_pat_secret_arn
        GITHUB_OWNER          = var.github_owner
        GITHUB_REPO           = var.github_repo
        GITHUB_BRANCH         = var.github_branch
        GITHUB_VALUES_PATH    = var.github_values_path
        POLL_TIMEOUT_SECONDS  = "600"
      }
    }
    post_failover_validation = {
      timeout = 300
      env = {
        SOURCE_REGION          = var.source_region
        DR_REGION              = var.dr_region
        GLOBAL_CLUSTER_ID      = var.global_cluster_id
        DR_CLUSTER_ARN         = var.dr_cluster_arn
        DR_EFS_ID              = var.dr_efs_id
        DR_ALB_HEALTH_URL      = var.public_health_check_url
        R53_DR_HEALTH_CHECK_ID = var.r53_dr_health_check_id
      }
    }
    approval_handler = {
      timeout = 30
      env = {
        DR_REGION              = var.dr_region
        APPROVAL_SHARED_SECRET = var.approval_shared_secret
      }
    }
  }
}

# Zip each Lambda's source directory.
data "archive_file" "lambdas" {
  for_each    = local.lambdas
  type        = "zip"
  source_dir  = "${path.module}/lambdas/${each.key}"
  output_path = "${path.module}/lambdas/${each.key}.zip"
}

# Per-Lambda execution role (trust policy + base CW Logs perm).
resource "aws_iam_role" "lambdas" {
  for_each = local.lambdas

  name = "${var.name_prefix}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  for_each   = local.lambdas
  role       = aws_iam_role.lambdas[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Per-Lambda policy granting the SPECIFIC AWS actions each needs.
locals {
  lambda_policies = {
    preflight_checks = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters",
          "elasticfilesystem:DescribeReplicationConfigurations",
          "elasticfilesystem:DescribeFileSystems",
          "eks:DescribeCluster",
          "route53:GetHostedZone",
        ]
        Resource = "*"
      }
    ]
    aurora_failover = [
      {
        Effect = "Allow"
        Action = [
          "rds:FailoverGlobalCluster",
          "rds:RemoveFromGlobalCluster",
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters",
        ]
        Resource = "*"
      }
    ]
    efs_promote = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteReplicationConfiguration",
          "elasticfilesystem:DescribeReplicationConfigurations",
          "elasticfilesystem:DescribeFileSystems",
        ]
        Resource = "*"
      }
    ]
    eks_scale = [
      {
        Effect = "Allow"
        Action = [
          "eks:UpdateNodegroupConfig",
          "eks:DescribeNodegroup",
          "eks:DescribeCluster",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.github_pat_secret_arn
      },
    ]
    post_failover_validation = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters",
          "elasticfilesystem:DescribeFileSystems",
          "route53:GetHealthCheckStatus",
        ]
        Resource = "*"
      }
    ]
    approval_handler = [
      {
        Effect = "Allow"
        Action = [
          "states:SendTaskSuccess",
          "states:SendTaskFailure",
          "states:SendTaskHeartbeat",
        ]
        Resource = "*"
      }
    ]
  }
}

resource "aws_iam_role_policy" "lambdas" {
  for_each = local.lambdas

  name = "${var.name_prefix}-${each.key}-policy"
  role = aws_iam_role.lambdas[each.key].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.lambda_policies[each.key]
  })
}

# CloudWatch log groups (created up-front so retention is set).
resource "aws_cloudwatch_log_group" "lambdas" {
  for_each = local.lambdas

  name              = "/aws/lambda/${var.name_prefix}-${each.key}"
  retention_in_days = 30
  tags              = var.tags
}

# The Lambda functions themselves.
resource "aws_lambda_function" "lambdas" {
  for_each = local.lambdas

  function_name = "${var.name_prefix}-${each.key}"
  role          = aws_iam_role.lambdas[each.key].arn
  runtime       = local.lambda_runtime
  handler       = "main.lambda_handler"
  memory_size   = local.lambda_memory
  timeout       = each.value.timeout

  filename         = data.archive_file.lambdas[each.key].output_path
  source_code_hash = data.archive_file.lambdas[each.key].output_base64sha256

  environment {
    variables = each.value.env
  }

  depends_on = [
    aws_cloudwatch_log_group.lambdas,
    aws_iam_role_policy.lambdas,
  ]

  tags = var.tags
}
