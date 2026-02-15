region            = "us-east-1"
release_name      = "argocd"
namespace         = "argocd"
create_namespace  = true
timeout           = 300
atomic            = false
manage_namespace  = false
set = {
  "server.service.type"               = "LoadBalancer"
  "configs.params.server\\.insecure" = "true"

  # Ingress settings kept for future use; currently disabled in favor of LB Service.
  # "global.domain" = "argocd.dev.example.com"
  # "server.ingress.enabled"                    = "true"
  # "server.ingress.controller"                 = "aws"
  # "server.ingress.ingressClassName"           = "alb"
  # "server.ingress.hostname"                   = "argocd.dev.example.com"
  # "server.ingress.tls"                        = "false"
  # "server.ingress.aws.backendProtocolVersion" = "HTTP1"
  # "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"           = "internet-facing"
  # "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"      = "ip"
  # "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"     = "[{\"HTTP\":80}]"
  # "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol" = "HTTP"
}
