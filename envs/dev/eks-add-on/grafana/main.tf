module "grafana" {
  source = "../../../../modules/eks-grafana"

  namespace                   = var.namespace
  grafana_release_name        = var.grafana_release_name
  grafana_chart_path          = var.grafana_chart_path
  grafana_image_registry      = var.grafana_image_registry
  grafana_image_repository    = var.grafana_image_repository
  grafana_image_tag           = var.grafana_image_tag
  init_chown_image_registry   = var.init_chown_image_registry
  init_chown_image_repository = var.init_chown_image_repository
  init_chown_image_tag        = var.init_chown_image_tag
}
