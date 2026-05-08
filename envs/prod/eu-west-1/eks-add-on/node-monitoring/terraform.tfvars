region = "eu-west-1"

namespace                       = "monitoring"
kube_state_metrics_release_name = "kube-state-metrics"
node_exporter_release_name      = "prometheus-node-exporter"

kube_state_metrics_chart_path = "../../../../modules/kube-state-metrics/kube-state-metrics"
node_exporter_chart_path      = "../../../../modules/node-exporter/prometheus-node-exporter"

kube_state_metrics_image_registry   = "495711089104.dkr.ecr.eu-west-1.amazonaws.com"
kube_state_metrics_image_repository = "thirdparty/kube-state-metrics"
kube_state_metrics_image_tag        = "v2.18.0-amd64-platform"

node_exporter_image_registry   = "495711089104.dkr.ecr.eu-west-1.amazonaws.com"
node_exporter_image_repository = "thirdparty/node-exporter"
node_exporter_image_tag        = "v1.10.2-amd64-platform"
