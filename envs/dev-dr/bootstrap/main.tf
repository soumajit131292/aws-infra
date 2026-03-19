provider "aws" {
  region = var.aws_region
}

data "aws_ecr_repositories" "all" {}

resource "aws_ecr_lifecycle_policy" "retain_last_n_images" {
  for_each = toset(data.aws_ecr_repositories.all.names)

  repository = each.value
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images beyond the latest ${var.ecr_max_images_per_repo} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_max_images_per_repo
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
