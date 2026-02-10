###############################
# IAM policy for ALB Controller
###############################

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-${var.region}"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/alb-controller-policy.json")

  tags = var.tags
}

########################################
# IAM role for ALB Controller (IRSA)
########################################

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(var.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

########################################
# Attach policy to role
########################################

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
