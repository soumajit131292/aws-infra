locals {
  kube_state_metrics_chart_path_effective = trimspace(var.kube_state_metrics_chart_path) != "" ? trimspace(var.kube_state_metrics_chart_path) : "${path.module}/../kube-state-metrics/kube-state-metrics"
  node_exporter_chart_path_effective      = trimspace(var.node_exporter_chart_path) != "" ? trimspace(var.node_exporter_chart_path) : "${path.module}/../node-exporter/prometheus-node-exporter"
}

resource "kubernetes_namespace" "monitoring" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "kube_state_metrics" {
  name      = var.kube_state_metrics_release_name
  namespace = var.namespace
  chart     = local.kube_state_metrics_chart_path_effective

  create_namespace = false
  wait             = true
  timeout          = 600

  values = concat([
    yamlencode({
      image = {
        registry   = var.kube_state_metrics_image_registry
        repository = var.kube_state_metrics_image_repository
        tag        = var.kube_state_metrics_image_tag
      }
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/path"   = "/metrics"
        "prometheus.io/port"   = "8080"
      }
    })
  ], var.kube_state_metrics_extra_values)

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "node_exporter" {
  name      = var.node_exporter_release_name
  namespace = var.namespace
  chart     = local.node_exporter_chart_path_effective

  create_namespace = false
  wait             = true
  timeout          = 600

  values = concat([
    yamlencode({
      image = {
        registry   = var.node_exporter_image_registry
        repository = var.node_exporter_image_repository
        tag        = var.node_exporter_image_tag
      }
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/path"   = "/metrics"
        "prometheus.io/port"   = "9100"
      }
    })
  ], var.node_exporter_extra_values)

  depends_on = [kubernetes_namespace.monitoring]
}
