output "release_name" {
  description = "The name of the Helm release for Metrics Server"
  value       = helm_release.metrics_server.name
}

output "release_namespace" {
  description = "The namespace of the Helm release for Metrics Server"
  value       = helm_release.metrics_server.namespace
}
