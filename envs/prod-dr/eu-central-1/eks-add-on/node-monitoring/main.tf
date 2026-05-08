module "node_monitoring" {
  source = "../../../../modules/eks-node-monitoring"

  namespace                           = var.namespace
  kube_state_metrics_release_name     = var.kube_state_metrics_release_name
  node_exporter_release_name          = var.node_exporter_release_name
  kube_state_metrics_chart_path       = var.kube_state_metrics_chart_path
  node_exporter_chart_path            = var.node_exporter_chart_path
  kube_state_metrics_image_registry   = var.kube_state_metrics_image_registry
  kube_state_metrics_image_repository = var.kube_state_metrics_image_repository
  kube_state_metrics_image_tag        = var.kube_state_metrics_image_tag
  node_exporter_image_registry        = var.node_exporter_image_registry
  node_exporter_image_repository      = var.node_exporter_image_repository
  node_exporter_image_tag             = var.node_exporter_image_tag
}
