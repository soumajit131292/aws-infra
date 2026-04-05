region                 = "us-east-1"
workspace_alias        = "dev-accesshub-amp"
existing_workspace_arn = ""
scraper_alias          = "dev-accesshub-eks-scraper"

scrape_configuration_yaml = <<-EOT
global:
  scrape_interval: 60s

scrape_configs:
  - job_name: kubelet
    kubernetes_sd_configs:
      - role: node

    scheme: https
    tls_config:
      insecure_skip_verify: true

    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    metric_relabel_configs:
      # Keep only accesshub namespace
      - source_labels: [namespace]
        regex: "accesshub"
        action: keep

      # Keep only CPU + memory
      - source_labels: [__name__]
        regex: "container_cpu_usage_seconds_total|container_memory_usage_bytes"
        action: keep

  - job_name: node-exporter
    kubernetes_sd_configs:
      - role: endpoints

    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: ".*node-exporter.*"
        action: keep

    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_filesystem_avail_bytes|node_filesystem_size_bytes|node_network_receive_bytes_total"
        action: keep

  - job_name: kube-state-metrics
    kubernetes_sd_configs:
        - role: endpoints

    relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          regex: "kube-state-metrics"
          action: keep

    metric_relabel_configs:
        # Keep only accesshub namespace
        - source_labels: [namespace]
          regex: "accesshub"
          action: keep

        # Keep only required metrics
        - source_labels: [__name__]
          regex: "kube_pod_status_phase|kube_deployment_status_replicas"
          action: keep

EOT

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
}
