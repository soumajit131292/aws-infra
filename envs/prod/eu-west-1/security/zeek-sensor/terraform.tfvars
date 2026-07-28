region        = "eu-west-1"
vpc_cidr      = "10.20.0.0/16"
instance_type = "m5.large"

# Fill with the EKS worker-node primary ENI IDs (see variable description /
# README for the discovery command). Empty = sensor deployed but nothing
# mirrored into it yet.
source_network_interface_ids = []

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Role        = "siem-zeek-sensor"
}
