region           = "us-east-1"
release_name     = "external-secrets"
namespace        = "external-secrets"
create_namespace = true
timeout          = 300
atomic           = false
manage_namespace = false

# Uncomment to force ECR image overrides after mirroring the image.
# values_files = ["../../../../modules/eks-eso/values-ecr-images.yaml"]

set = {}
