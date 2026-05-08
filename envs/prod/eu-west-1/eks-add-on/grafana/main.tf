module "grafana" {
  source = "../../../../../modules/eks-grafana"

  namespace                   = var.namespace
  create_namespace            = var.create_namespace
  grafana_release_name        = var.grafana_release_name
  grafana_chart_path          = var.grafana_chart_path
  grafana_image_registry      = var.grafana_image_registry
  grafana_image_repository    = var.grafana_image_repository
  grafana_image_tag           = var.grafana_image_tag
  init_chown_image_registry   = var.init_chown_image_registry
  init_chown_image_repository = var.init_chown_image_repository
  init_chown_image_tag        = var.init_chown_image_tag
  cluster_name                = data.terraform_remote_state.eks.outputs.cluster_name
  oidc_provider_arn           = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer_url             = data.terraform_remote_state.eks.outputs.oidc_issuer_url
  service_account_name        = var.service_account_name
  enable_irsa                 = var.enable_irsa
  irsa_role_name              = var.irsa_role_name
  enable_amp_datasource       = var.enable_amp_datasource
  amp_region                  = var.region
  amp_datasource_name         = var.amp_datasource_name
  amp_datasource_type         = var.amp_datasource_type
  enable_amp_plugin_install   = var.enable_amp_plugin_install
  amp_plugin_id               = var.amp_plugin_id
  grafana_plugins             = var.grafana_plugins
  amp_workspace_arn           = trimspace(var.amp_workspace_arn) != "" ? trimspace(var.amp_workspace_arn) : data.terraform_remote_state.managed_prometheus.outputs.workspace_arn
  grafana_extra_values        = var.grafana_extra_values
}
