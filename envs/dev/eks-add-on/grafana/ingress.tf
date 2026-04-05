resource "kubernetes_ingress_v1" "grafana" {
  count = var.enable_grafana_ingress ? 1 : 0

  metadata {
    name        = var.grafana_ingress_name
    namespace   = var.namespace
    annotations = var.grafana_ingress_annotations
  }

  spec {
    ingress_class_name = var.grafana_ingress_class_name

    rule {
      host = trimspace(var.grafana_ingress_host) != "" ? trimspace(var.grafana_ingress_host) : null

      http {
        path {
          path      = var.grafana_ingress_path
          path_type = "Prefix"

          backend {
            service {
              name = var.grafana_ingress_service_name

              port {
                number = var.grafana_ingress_service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [module.grafana]
}
