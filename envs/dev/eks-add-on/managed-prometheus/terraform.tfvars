region                 = "us-east-1"
workspace_alias        = "dev-accesshub-amp"
existing_workspace_arn = ""
scraper_alias          = "dev-accesshub-eks-scraper"

scrape_configuration_yaml = <<-EOT
global:
  scrape_interval: 60s

scrape_configs:
  # NODE EXPORTER
  - job_name: node-exporter
    kubernetes_sd_configs:
      - role: endpoints

    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: ".*node-exporter.*"
        action: keep
      - source_labels: [__meta_kubernetes_namespace]
        regex: "monitoring"
        action: keep

    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_filesystem_avail_bytes|node_filesystem_size_bytes|node_network_receive_bytes_total"
        action: keep

  # KUBE-STATE-METRICS
  - job_name: kube-state-metrics
    kubernetes_sd_configs:
      - role: endpoints

    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: "kube-state-metrics"
        action: keep
      - source_labels: [__meta_kubernetes_namespace]
        regex: "monitoring"
        action: keep

    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "kube_pod_status_phase|kube_deployment_status_replicas"
        action: keep
EOT

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
}
