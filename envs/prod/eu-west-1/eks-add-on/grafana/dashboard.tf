resource "kubernetes_config_map" "accesshub_dashboard" {
  metadata {
    name      = "grafana-dashboard-accesshub"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "accesshub-observability.json" = file("${path.module}/scripts/daashboard.json")
  }

  depends_on = [module.grafana]
}
