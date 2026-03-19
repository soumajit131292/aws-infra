locals {
  workspace_arn = trimspace(var.existing_workspace_arn) != "" ? var.existing_workspace_arn : aws_prometheus_workspace.this[0].arn
}

resource "aws_prometheus_workspace" "this" {
  count = trimspace(var.existing_workspace_arn) == "" ? 1 : 0

  alias = var.workspace_alias

  tags = var.tags
}

resource "aws_prometheus_scraper" "eks" {
  alias = var.scraper_alias

  destination {
    amp {
      workspace_arn = local.workspace_arn
    }
  }

  scrape_configuration = base64encode(var.scrape_configuration_yaml)

  source {
    eks {
      cluster_arn = data.aws_eks_cluster.this.arn
      subnet_ids  = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids
      security_group_ids = [
        data.terraform_remote_state.eks.outputs.cluster_security_group_id
      ]
    }
  }

  tags = var.tags
}
