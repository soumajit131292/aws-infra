variable "region" {
  description = "AWS region where this stack runs. Aurora Global Cluster is region-agnostic in the API, but the call is made from the primary's region."
  type        = string
}

variable "global_cluster_identifier" {
  description = "Identifier for the Aurora Global Cluster. Used by secondary clusters via global_cluster_identifier."
  type        = string
}

variable "force_destroy" {
  description = "When true, allows the global cluster to be destroyed even if it has members. Keep false in prod."
  type        = bool
  default     = false
}
