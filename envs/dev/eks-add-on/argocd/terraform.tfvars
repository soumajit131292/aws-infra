region            = "us-east-1"
release_name      = "argocd"
namespace         = "argocd"
create_namespace  = true
timeout           = 600

set = {
  "server.service.type" = "LoadBalancer"
}
