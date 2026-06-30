output "release_name" {
  description = "The name of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "release_namespace" {
  description = "The namespace of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.namespace
}
