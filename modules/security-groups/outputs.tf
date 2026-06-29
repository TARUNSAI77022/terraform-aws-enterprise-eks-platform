output "alb_sg_id" {
  description = "The ID of the Application Load Balancer Security Group"
  value       = aws_security_group.alb_sg.id
}

output "app_node_sg_id" {
  description = "The ID of the Unified Application Node Security Group"
  value       = aws_security_group.app_node_sg.id
}

output "ssm_bastion_sg_id" {
  description = "The ID of the SSM Bastion Host Security Group"
  value       = aws_security_group.ssm_bastion_sg.id
}

output "db_sg_id" {
  description = "The ID of the PostgreSQL Database Security Group"
  value       = aws_security_group.db_sg.id
}

output "eks_cluster_sg_id" {
  description = "The ID of the EKS Cluster Control Plane Security Group"
  value       = aws_security_group.eks_cluster_sg.id
}
