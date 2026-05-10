region           = "eu-west-1"
release_name     = "argocd"
namespace        = "argocd"
create_namespace = true
timeout          = 300
atomic           = false
manage_namespace = false
values_files     = ["./values-ecr-images.yaml"]
set = {
  "server.service.type"                                                         = "ClusterIP"
  "configs.params.server\\.insecure"                                            = "true"
  "server.ingress.enabled"                                                      = "true"
  "server.ingress.controller"                                                   = "aws"
  "server.ingress.ingressClassName"                                             = "alb"
  "global.domain"                                                               = ""
  "server.ingress.hostname"                                                     = ""
  "server.ingress.tls"                                                          = "false"
  "server.ingress.aws.backendProtocolVersion"                                   = "HTTP1"
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"           = "internet-facing"
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"      = "ip"
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"     = "[{\"HTTP\":80}]"
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol" = "HTTP"
}

values = [
  <<-EOT
  server:
    ingress:
      extraRules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: '{{ include "argo-cd.server.fullname" . }}'
                    port:
                      name: '{{ .Values.server.service.servicePortHttpName }}'
  EOT
]
