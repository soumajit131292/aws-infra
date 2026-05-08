variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "workspace_alias" {
  description = "Alias for AMP workspace when creating a new workspace."
  type        = string
  default     = "prod-dr-accesshub-amp"
}

variable "existing_workspace_arn" {
  description = "Use an existing AMP workspace ARN. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "scraper_alias" {
  description = "Alias for the managed scraper."
  type        = string
  default     = "prod-dr-accesshub-eks-scraper"
}

variable "scrape_configuration_yaml" {
  description = "Prometheus scrape configuration YAML."
  type        = string
  default     = <<-EOT
    global:
      scrape_interval: 30s
    scrape_configs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\\d+)?;(\\d+)
            replacement: $$1:$$2
            target_label: __address__
  EOT
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    Environment = "prod-dr"
    ManagedBy   = "terraform"
  }
}
