output "node_group_arns" {
  description = "Map of node group keys to their ARNs"
  value       = { for k, v in aws_eks_node_group.this : k => v.arn }
}

output "node_group_names" {
  description = "Map of node group keys to their names"
  value       = { for k, v in aws_eks_node_group.this : k => v.node_group_name }
}

output "autoscaling_group_names" {
  description = "Map of node group keys to their Auto Scaling Group names"
  value       = { for k, v in aws_eks_node_group.this : k => flatten(v.resources[*].autoscaling_groups[*].name) }
}
