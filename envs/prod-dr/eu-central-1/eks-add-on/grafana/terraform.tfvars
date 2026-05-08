region = "eu-central-1"

namespace            = "monitoring"
create_namespace     = false
grafana_release_name = "grafana"

grafana_chart_path = "../../../../modules/grafana/grafana"

grafana_image_registry   = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
grafana_image_repository = "thirdparty/grafana"
grafana_image_tag        = "12.3.1-amd64-platform"

init_chown_image_registry   = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
init_chown_image_repository = "thirdparty/busybox"
init_chown_image_tag        = "1.31.1-amd64-platform"

service_account_name      = "grafana"
enable_irsa               = true
irsa_role_name            = ""
enable_amp_datasource     = true
amp_workspace_arn         = ""
amp_datasource_name       = "AMP"
amp_datasource_type       = "grafana-amazonprometheus-datasource"
enable_amp_plugin_install = true
amp_plugin_id             = "grafana-amazonprometheus-datasource"
grafana_plugins           = []

grafana_extra_values = [
  <<-EOT
grafana.ini:
  server:
    root_url: "%(protocol)s://%(domain)s/grafana/"
    serve_from_sub_path: true
sidecar:
  dashboards:
    enabled: true
    label: grafana_dashboard
    labelValue: "1"
    searchNamespace: monitoring
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
      - name: default
        orgId: 1
        folder: ""
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
EOT
]

enable_grafana_ingress       = true
grafana_ingress_name         = "grafana-ingress"
grafana_ingress_class_name   = "alb"
grafana_ingress_host         = ""
grafana_ingress_path         = "/grafana"
grafana_ingress_service_name = "grafana"
grafana_ingress_service_port = 80

grafana_ingress_annotations = {
  "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
  "alb.ingress.kubernetes.io/group.name"       = "accesshub-dev"
  "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
  "alb.ingress.kubernetes.io/inbound-cidrs"    = "0.0.0.0/0"
  "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80}]"
  "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
  "alb.ingress.kubernetes.io/success-codes"    = "200-399"
  "alb.ingress.kubernetes.io/target-type"      = "ip"
}
