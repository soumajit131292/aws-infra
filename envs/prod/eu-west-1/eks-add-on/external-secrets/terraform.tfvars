region               = "eu-west-1"
release_name         = "external-secrets"
namespace            = "external-secrets"
create_namespace     = true
timeout              = 300
atomic               = false
manage_namespace     = false
service_account_name = "external-secrets"
values_files         = ["./values-ecr-images.yaml"]

# Uncomment to force ECR image overrides after mirroring the image.
# values_files = ["../../../../modules/eks-eso/values-ecr-images.yaml"]

# Narrow this to exact secret ARNs in production.
secrets_manager_secret_arns = ["*"]

# Set if your secrets use customer-managed KMS keys.
# kms_key_arns = ["arn:aws:kms:us-east-1:495711089104:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]

create_cluster_secret_store = true
cluster_secret_store_name   = "aws-secretsmanager"

set = {}
