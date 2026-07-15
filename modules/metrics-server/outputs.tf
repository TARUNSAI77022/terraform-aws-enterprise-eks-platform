output "release_name" {
  description = "The name of the Helm release for Metrics Server"
  value       = var.enable ? helm_release.metrics_server[0].name : ""
}

output "release_namespace" {
  description = "The namespace of the Helm release for Metrics Server"
  value       = var.enable ? helm_release.metrics_server[0].namespace : ""
}
