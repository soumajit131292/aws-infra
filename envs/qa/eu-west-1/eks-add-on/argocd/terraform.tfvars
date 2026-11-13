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
  # QA-only ALB name and ingress group, so it never joins a prod ALB group.
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name" = "qa-argocd-alb"
  "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/group\\.name"       = "qa-argocd"
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

# REQUIRED: who may reach the QA Argo CD UI. Internet-facing ALB, HTTP, no WAF
# in QA — restrict it to your office/VPN egress IPs (e.g. "203.0.113.10/32").
inbound_cidrs = ["REPLACE_WITH_OFFICE_OR_VPN_CIDR"]

# Optional: a QA WAFv2 web ACL ARN. Leave empty; never the prod ACL.
waf_acl_arn = ""
