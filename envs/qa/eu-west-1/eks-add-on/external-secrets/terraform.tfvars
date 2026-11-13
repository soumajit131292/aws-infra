region               = "eu-west-1"
release_name         = "external-secrets"
namespace            = "external-secrets"
create_namespace     = true
timeout              = 300
atomic               = false
manage_namespace     = false
service_account_name = "external-secrets"
values_files         = ["./values-ecr-images.yaml"]


# QA can read only qa/* secrets in this account/region. Prod and QA share the
# account, so "*" would let the QA cluster read prod secrets.
secrets_manager_secret_arns = ["arn:aws:secretsmanager:eu-west-1:495711089104:secret:qa/*"]

# Set if your secrets use customer-managed KMS keys.
# kms_key_arns = ["arn:aws:kms:eu-west-1:495711089104:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]

create_cluster_secret_store = true
cluster_secret_store_name   = "aws-secretsmanager"

set = {}
