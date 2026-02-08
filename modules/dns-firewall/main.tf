
provider "aws" {
  region = "us-east-1"
}

###############################
# Allow-list domains required by EKS
###############################
resource "aws_route53_resolver_firewall_domain_list" "eks_allow" {
  name = "eks-allow-domains"

  domains = [
    "*.eks.us-east-1.amazonaws.com",
    "*.amazonaws.com",
    "amazonaws.com"
  ]

  tags = {
    Name = "eks-allow-domains"
  }
}

###############################
# DNS Firewall Rule Group
###############################
resource "aws_route53_resolver_firewall_rule_group" "eks" {
  name = "eks-dns-firewall-group"

  tags = {
    Name = "eks-dns-firewall-group"
  }
}

###############################
# ALLOW rule (high priority)
###############################
resource "aws_route53_resolver_firewall_rule" "allow_eks" {
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.eks.id
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.eks_allow.id

  priority = 10
  action   = "ALLOW"
  name     = "allow-eks-domains"
}

###############################
# Associate DNS Firewall with VPC
###############################
resource "aws_route53_resolver_firewall_rule_group_association" "eks_vpc" {
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.eks.id
  vpc_id                = var.vpc_id

  priority = 101
  name     = "eks-dns-firewall-association"
}
