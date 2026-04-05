region                 = "us-east-1"
workspace_alias        = "dev-accesshub-amp"
existing_workspace_arn = ""
scraper_alias          = "dev-accesshub-eks-scraper"

scrape_configuration_yaml = <<-EOT
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod

    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        regex: true
        action: keep
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\\d+)?;(\\d+)
        replacement: $1:$2
        target_label: __address__
EOT

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
}
