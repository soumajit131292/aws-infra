locals {
  grafana_chart_path_effective = trimspace(var.grafana_chart_path) != "" ? trimspace(var.grafana_chart_path) : "${path.module}/../grafana/grafana"
}

resource "kubernetes_namespace" "grafana" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "grafana" {
  name      = var.grafana_release_name
  namespace = var.namespace
  chart     = local.grafana_chart_path_effective

  create_namespace = false
  wait             = true
  timeout          = 600

  values = concat([
    yamlencode({
      image = {
        registry   = var.grafana_image_registry
        repository = var.grafana_image_repository
        tag        = var.grafana_image_tag
      }
      testFramework = {
        enabled = false
      }
      initChownData = {
        enabled = true
        image = {
          registry   = var.init_chown_image_registry
          repository = var.init_chown_image_repository
          tag        = var.init_chown_image_tag
        }
      }
    })
  ], var.grafana_extra_values)

  depends_on = [kubernetes_namespace.grafana]
}
