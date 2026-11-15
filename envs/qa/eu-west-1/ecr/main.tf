#############################################
# QA image repositories: accesshub-qa/<service>
#
# Separate from the prod/dev accesshub/* repositories. QA builds
# (build-from-app-repo.yml, build-health-aggregator.yml) push here with the
# QA GitHub role, and values-qa.yaml / values-health-qa.yaml point here.
# QA nodes pull with the node role's AmazonEC2ContainerRegistryReadOnly.
#############################################
resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name                 = "${var.repository_prefix}/${each.value}"
  image_tag_mutability = "IMMUTABLE" # sha-<commit> tags must never be overwritten

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # QA can be torn down; images are rebuilt from git.
  force_delete = var.force_delete
}

# Keep the last N images per repository; QA builds on every push.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last ${var.keep_last_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.keep_last_images
      }
      action = { type = "expire" }
    }]
  })
}
