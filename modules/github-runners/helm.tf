resource "helm_release" "arc" {
  name      = "arc"
  namespace = "actions-runner-system"
  chart     = "${path.module}/actions-runner-controller"

  create_namespace = true
  skip_crds        = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      image = {
        repository                    = var.arc_controller_image_repository
        tag                           = var.arc_controller_image_tag
        actionsRunnerRepositoryAndTag = "${var.runner_image_repository}:${var.runner_image_tag}"
      }
      metrics = {
        proxy = {
          image = {
            repository = var.kube_rbac_proxy_image_repository
            tag        = var.kube_rbac_proxy_image_tag
          }
        }
      }
      actionsMetrics = {
        proxy = {
          image = {
            repository = var.kube_rbac_proxy_image_repository
            tag        = var.kube_rbac_proxy_image_tag
          }
        }
      }
      certManagerEnabled = false
      nodeSelector       = var.controller_node_selector
      authSecret = {
        create                     = true
        name                       = "controller-manager"
        github_app_id              = var.github_app_id
        github_app_installation_id = var.github_installation_id
        github_app_private_key     = var.github_private_key
      }
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
      image = {
        repository = var.cluster_autoscaler_image_repository
        tag        = var.cluster_autoscaler_image_tag
      }
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      awsRegion    = var.aws_region
      nodeSelector = var.controller_node_selector
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
