region = "us-east-1"

namespace            = "monitoring"
grafana_release_name = "grafana"

grafana_chart_path = "../../../../modules/grafana/grafana"

grafana_image_registry   = "495711089104.dkr.ecr.us-east-1.amazonaws.com"
grafana_image_repository = "thirdparty/grafana"
grafana_image_tag        = "12.3.1-amd64-platform"

init_chown_image_registry   = "495711089104.dkr.ecr.us-east-1.amazonaws.com"
init_chown_image_repository = "thirdparty/busybox"
init_chown_image_tag        = "1.31.1-amd64-platform"

service_account_name  = "grafana"
enable_irsa           = true
irsa_role_name        = ""
enable_amp_datasource = true
amp_workspace_arn     = ""
amp_datasource_name   = "AMP"
