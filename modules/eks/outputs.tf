output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for EKS"
  value       = var.create_oidc_provider ? (length(aws_iam_openid_connect_provider.this) > 0 ? aws_iam_openid_connect_provider.this[0].arn : "") : var.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Provider for EKS"
  value       = var.create_oidc_provider ? aws_eks_cluster.this.identity[0].oidc[0].issuer : var.oidc_provider_url
}

output "cluster_security_group_id" {
  description = "The ID of the security group created by AWS EKS automatically"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
