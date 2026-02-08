variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}


variable "tags" {
  type = map(string)
}
