# Primary provider: DR region (eu-central-1). State machine, Lambdas, API
# Gateway, and the DR-side SNS topic + alarms live here. Triggerable even if
# prod region is unreachable.
provider "aws" {
  region = var.dr_region
}

# Source region (eu-west-1) — used for ALB lookup, ALB alarms, prod-Aurora
# alarms, AWS Health events scoped to source region, and the local SNS
# topic that those alarms publish to.
provider "aws" {
  alias  = "source"
  region = var.source_region
}

# us-east-1 — used for the Route 53 health-check CloudWatch alarm
# (HealthCheckStatus metrics only publish in us-east-1).
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.31.0"
      configuration_aliases = [aws.source, aws.us_east_1]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
