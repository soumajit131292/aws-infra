terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31.0"
      # aws            -> default (DR region, eu-central-1)
      # aws.source     -> source/primary region (eu-west-1) — needed for ALB + prod-Aurora alarms
      # aws.us_east_1  -> us-east-1 — needed for Route 53 health-check metrics
      configuration_aliases = [aws.source, aws.us_east_1]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
