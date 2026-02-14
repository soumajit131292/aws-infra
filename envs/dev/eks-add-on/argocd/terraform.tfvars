region            = "us-east-1"
release_name      = "argocd"
namespace         = "argocd"
create_namespace  = true
timeout           = 600
manage_namespace   = false
set = {
  "server.service.type" = "LoadBalancer"
}
