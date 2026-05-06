output "arc_namespace" {
  description = "Namespace where actions-runner-controller is deployed"
  value       = module.github_runners.arc_namespace
}

output "runner_deployment_name" {
  description = "RunnerDeployment name created by ARC"
  value       = module.github_runners.runner_deployment_name
}
