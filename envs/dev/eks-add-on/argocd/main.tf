module "argocd" {
  source = "../../../../modules/eks-argocd"

  release_name     = var.release_name
  namespace        = var.namespace
  chart_path       = var.chart_path
  create_namespace = var.create_namespace
  manage_namespace = var.manage_namespace
  timeout          = var.timeout
  # atomic           = var.atomic
  values_files     = var.values_files
  values           = var.values
  set              = var.set
}
