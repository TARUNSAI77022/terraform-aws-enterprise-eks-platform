output "release_name" {
  description = "The name of the Helm release for Cluster Autoscaler"
  value       = helm_release.cluster_autoscaler.name
}

output "release_namespace" {
  description = "The namespace of the Helm release for Cluster Autoscaler"
  value       = helm_release.cluster_autoscaler.namespace
}
