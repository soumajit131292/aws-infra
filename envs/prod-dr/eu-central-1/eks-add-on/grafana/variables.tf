variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for Grafana add-on."
  type        = string
  default     = "monitoring"
}

variable "create_namespace" {
  description = "Whether Grafana stack should create the namespace."
  type        = bool
  default     = false
}

variable "grafana_release_name" {
  description = "Helm release name for Grafana."
  type        = string
  default     = "grafana"
}

variable "grafana_chart_path" {
  description = "Path to local Grafana chart."
  type        = string
  default     = "../../../../../modules/grafana/grafana"
}

variable "grafana_image_registry" {
  description = "Image registry for Grafana."
  type        = string
  default     = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
}

variable "grafana_image_repository" {
  description = "Image repository for Grafana."
  type        = string
  default     = "thirdparty/grafana"
}

variable "grafana_image_tag" {
  description = "Image tag for Grafana."
  type        = string
  default     = "12.3.1-amd64-platform"
}

variable "init_chown_image_registry" {
  description = "Image registry for initChownData container."
  type        = string
  default     = "495711089104.dkr.ecr.eu-central-1.amazonaws.com"
}

variable "init_chown_image_repository" {
  description = "Image repository for initChownData container."
  type        = string
  default     = "thirdparty/busybox"
}

variable "init_chown_image_tag" {
  description = "Image tag for initChownData container."
  type        = string
  default     = "1.31.1-amd64-platform"
}

variable "service_account_name" {
  description = "Grafana Kubernetes service account name."
  type        = string
  default     = "grafana"
}

variable "enable_irsa" {
  description = "Create IRSA role and annotate Grafana service account."
  type        = bool
  default     = true
}

variable "irsa_role_name" {
  description = "Optional custom IAM role name for Grafana IRSA."
  type        = string
  default     = ""
}

variable "enable_amp_datasource" {
  description = "Configure AMP datasource in Grafana values."
  type        = bool
  default     = true
}

variable "amp_workspace_arn" {
  description = "Optional AMP workspace ARN override; if empty, it is read from managed-prometheus remote state."
  type        = string
  default     = ""
}

variable "amp_datasource_name" {
  description = "Grafana datasource name for AMP."
  type        = string
  default     = "AMP"
}

variable "amp_datasource_type" {
  description = "Grafana datasource plugin type for AMP."
  type        = string
  default     = "grafana-amazonprometheus-datasource"
}

variable "enable_amp_plugin_install" {
  description = "Install AMP datasource plugin in Grafana."
  type        = bool
  default     = true
}

variable "amp_plugin_id" {
  description = "Grafana AMP datasource plugin id."
  type        = string
  default     = "grafana-amazonprometheus-datasource"
}

variable "grafana_plugins" {
  description = "Additional Grafana plugins to install."
  type        = list(string)
  default     = []
}

variable "grafana_extra_values" {
  description = "Additional Helm values snippets for Grafana."
  type        = list(string)
  default     = []
}

variable "enable_grafana_ingress" {
  description = "Whether to create Grafana Ingress."
  type        = bool
  default     = true
}

variable "grafana_ingress_name" {
  description = "Name of Grafana Ingress resource."
  type        = string
  default     = "grafana-ingress"
}

variable "grafana_ingress_class_name" {
  description = "Ingress class name for Grafana Ingress."
  type        = string
  default     = "alb"
}

variable "grafana_ingress_host" {
  description = "Optional host for Grafana Ingress. Leave empty to match all hosts."
  type        = string
  default     = ""
}

variable "grafana_ingress_path" {
  description = "Path for Grafana Ingress route."
  type        = string
  default     = "/grafana"
}

variable "grafana_ingress_service_name" {
  description = "Service name used by Grafana Ingress backend."
  type        = string
  default     = "grafana"
}

variable "grafana_ingress_service_port" {
  description = "Service port used by Grafana Ingress backend."
  type        = number
  default     = 80
}

variable "grafana_ingress_annotations" {
  description = "Annotations applied to Grafana Ingress."
  type        = map(string)
  default = {
    "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
    "alb.ingress.kubernetes.io/group.name"       = "accesshub-dev"
    "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    "alb.ingress.kubernetes.io/inbound-cidrs"    = "0.0.0.0/0"
    "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80}]"
    "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
    "alb.ingress.kubernetes.io/success-codes"    = "200-399"
    "alb.ingress.kubernetes.io/target-type"      = "ip"
  }
}
