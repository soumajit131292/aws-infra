module "argocd" {
  source = "../../../../../modules/eks-argocd"

  release_name     = var.release_name
  namespace        = var.namespace
  chart_path       = var.chart_path
  create_namespace = var.create_namespace
  manage_namespace = var.manage_namespace
  timeout          = var.timeout
  # atomic           = var.atomic
  values_files = var.values_files
  values       = var.values
  set = merge(
    var.set,
    {
      "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/subnets"       = join("\\,", data.aws_subnets.alb_public.ids)
      "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/wafv2-acl-arn" = data.terraform_remote_state.waf.outputs.web_acl_arn
    }
  )
}
