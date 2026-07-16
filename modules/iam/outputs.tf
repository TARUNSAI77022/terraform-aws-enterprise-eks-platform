output "eks_cluster_role_arn" {
  description = "The ARN of the EKS Cluster IAM Role"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_role_arn" {
  description = "The ARN of the EKS Node Group IAM Role"
  value       = aws_iam_role.node_group.arn
}

output "ebs_csi_role_arn" {
  description = "The ARN of the EBS CSI Driver IAM Role"
  value       = aws_iam_role.ebs_csi.arn
}

output "aws_lb_controller_role_arn" {
  description = "The ARN of the AWS Load Balancer Controller IAM Role"
  value       = aws_iam_role.aws_lb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "The ARN of the Cluster Autoscaler IAM Role"
  value       = aws_iam_role.cluster_autoscaler.arn
}
