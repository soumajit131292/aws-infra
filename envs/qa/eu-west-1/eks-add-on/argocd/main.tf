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
      "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/inbound-cidrs" = join("\\,", var.inbound_cidrs)
    },
    # QA has no WAF yet. Set waf_acl_arn to a QA web ACL to attach one; never
    # point it at the prod ACL.
    var.waf_acl_arn != "" ? {
      "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/wafv2-acl-arn" = var.waf_acl_arn
    } : {}
  )
}
