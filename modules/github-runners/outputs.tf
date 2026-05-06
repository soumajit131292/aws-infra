output "arc_namespace" {
  value = "actions-runner-system"
}
output "runner_deployment_name" {
  value = kubernetes_manifest.runner.manifest["metadata"]["name"]
}