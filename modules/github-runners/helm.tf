resource "helm_release" "arc" {
  name       = "arc"
  namespace  = "actions-runner-system"
  chart = "${path.module}/helm-chart/actions-runner-controller"

  create_namespace = true

  values = [
    yamlencode({
      authSecret = { create = false }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.arc_controller.arn
        }
      }
    })
  ]
}
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      awsRegion = var.aws_region
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
          }
        }
      }
    })
  ]
}

resource "kubernetes_secret" "arc_auth" {
  metadata {
    name      = "controller-manager"
    namespace = "actions-runner-system"
  }

  data = {
    github_app_id              = var.github_app_id
    github_app_installation_id = var.github_installation_id
    github_app_private_key     = var.github_private_key
  }

  depends_on = [helm_release.arc]
}
