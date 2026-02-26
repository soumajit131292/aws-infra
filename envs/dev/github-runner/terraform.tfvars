region = "us-east-1"

github_org             = "your-github-org"
github_app_id          = "123456"
github_installation_id = "98765432"

# Paste full GitHub App private key PEM.
github_private_key = <<-EOT
-----BEGIN RSA PRIVATE KEY-----
REPLACE_ME
-----END RSA PRIVATE KEY-----
EOT

runner_max_replicas = 3

# Uncomment after mirroring images to ECR:
# arc_controller_image_repository     = "495711089104.dkr.ecr.us-east-1.amazonaws.com/thirdparty/actions-runner-controller"
# arc_controller_image_tag            = "v0.27.6-amd64-platform"
# runner_image_repository             = "495711089104.dkr.ecr.us-east-1.amazonaws.com/thirdparty/actions-runner"
# runner_image_tag                    = "latest-amd64-platform"
# kube_rbac_proxy_image_repository    = "495711089104.dkr.ecr.us-east-1.amazonaws.com/thirdparty/kube-rbac-proxy"
# kube_rbac_proxy_image_tag           = "v0.13.1-amd64-platform"
# cluster_autoscaler_image_repository = "495711089104.dkr.ecr.us-east-1.amazonaws.com/thirdparty/cluster-autoscaler"
# cluster_autoscaler_image_tag        = "v1.31.0-amd64-platform"
