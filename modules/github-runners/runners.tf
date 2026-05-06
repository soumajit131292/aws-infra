resource "kubernetes_manifest" "runner" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "shared-runner"
      namespace = "actions-runner-system"
    }
    spec = {
      replicas = 0
      template = {
        spec = {
          organization = var.github_org
          ephemeral    = true
          labels       = ["eks", "shared"]
          nodeSelector = var.runner_node_selector
          tolerations = [
            {
              key      = var.runner_taint_key
              operator = "Equal"
              value    = var.runner_taint_value
              effect   = "NoSchedule"
            }
          ]

          resources = {
            requests = {
              cpu    = "1"
              memory = "4Gi"
            }
            limits = {
              cpu    = "1"
              memory = "4Gi"
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.arc]
}
resource "kubernetes_manifest" "runner_autoscaler" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "shared-runner-autoscaler"
      namespace = "actions-runner-system"
    }
    spec = {
      scaleTargetRef = {
        name = "shared-runner"
      }
      minReplicas = 0
      maxReplicas = var.runner_max_replicas
      metrics = [{
        type               = "PercentageRunnersBusy"
        scaleUpThreshold   = "70"
        scaleDownThreshold = "30"
      }]
    }
  }
}
