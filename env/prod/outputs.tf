# ------------------------------------------------------------------------------
# Phase 1 VPC and Cloud Foundation Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "The IDs of the private application subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "The IDs of the private database subnets"
  value       = module.vpc.database_subnet_ids
}

output "database_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ips" {
  description = "The public Elastic IP addresses of the NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_id" {
  description = "The ID of the database route table"
  value       = module.vpc.database_route_table_id
}

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------
output "app_node_security_group_id" {
  description = "The ID of the Unified Host Security Group"
  value       = module.security_groups.app_node_sg_id
}

output "ssm_bastion_security_group_id" {
  description = "The ID of the SSM Bastion Host Security Group"
  value       = module.security_groups.ssm_bastion_sg_id
}

output "database_security_group_id" {
  description = "The ID of the PostgreSQL Database Security Group"
  value       = module.security_groups.db_sg_id
}

output "eks_cluster_security_group_id" {
  description = "The ID of the EKS Cluster Control Plane Security Group"
  value       = module.security_groups.eks_cluster_sg_id
}

output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group securing the interface VPC endpoints"
  value       = module.vpc.vpc_endpoint_sg_id
}

# ------------------------------------------------------------------------------
# VPC Endpoint Outputs
# ------------------------------------------------------------------------------
output "vpc_endpoint_ids" {
  description = "A map of service key to VPC Endpoint ID for interface endpoints"
  value       = module.vpc.vpc_endpoint_ids
}

output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint"
  value       = module.vpc.s3_endpoint_id
}

# ------------------------------------------------------------------------------
# Phase 2: KMS Outputs
# ------------------------------------------------------------------------------
output "kms_eks_key_arn" {
  description = "The ARN of the KMS key used for EKS Secrets encryption"
  value       = module.kms.eks_kms_key_arn
}

output "kms_cloudwatch_key_arn" {
  description = "The ARN of the KMS key used for CloudWatch Logs encryption"
  value       = module.kms.cloudwatch_kms_key_arn
}

output "kms_ecr_key_arn" {
  description = "The ARN of the KMS key used for ECR Repository encryption"
  value       = module.kms.ecr_kms_key_arn
}

# ------------------------------------------------------------------------------
# Phase 2: ECR Outputs
# ------------------------------------------------------------------------------
output "ecr_repository_names" {
  description = "A map of repository key to actual AWS ECR repository name"
  value       = module.ecr.repository_names
}

output "ecr_repository_urls" {
  description = "A map of repository key to repository URL"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "A map of repository key to repository ARN"
  value       = module.ecr.repository_arns
}

# ------------------------------------------------------------------------------
# Phase 2: CloudWatch Outputs
# ------------------------------------------------------------------------------
output "eks_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for EKS cluster logs"
  value       = module.cloudwatch.log_group_arn
}

# ------------------------------------------------------------------------------
# Phase 2: EKS Control Plane Outputs
# ------------------------------------------------------------------------------
output "eks_cluster_name" {
  description = "The name of the EKS Cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS Cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "The EKS Cluster Control Plane API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "The Base64 encoded public certificate authority data of EKS Cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OpenID Connect (OIDC) provider for IAM roles"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "The URL of the OpenID Connect (OIDC) provider for IAM roles"
  value       = module.eks.oidc_provider_url
}

output "eks_cluster_primary_security_group_id" {
  description = "The primary security group ID created automatically by AWS EKS"
  value       = module.eks.cluster_security_group_id
}

# ------------------------------------------------------------------------------
# Phase 2: EKS Managed Node Group Outputs
# ------------------------------------------------------------------------------
output "node_group_arns" {
  description = "Map of EKS node group keys to their ARNs"
  value       = module.node_groups.node_group_arns
}

output "node_group_names" {
  description = "Map of EKS node group keys to their names"
  value       = module.node_groups.node_group_names
}

output "node_group_autoscaling_group_names" {
  description = "Map of EKS node group keys to their Auto Scaling Group names"
  value       = module.node_groups.autoscaling_group_names
}

# ------------------------------------------------------------------------------
# Phase 2: IAM Outputs
# ------------------------------------------------------------------------------
output "iam_eks_cluster_role_arn" {
  description = "The ARN of the EKS Cluster control plane IAM Role"
  value       = module.iam.eks_cluster_role_arn
}

output "iam_node_group_role_arn" {
  description = "The ARN of the EKS Worker Node Group IAM Role"
  value       = module.iam.node_group_role_arn
}

output "iam_ebs_csi_role_arn" {
  description = "The ARN of the EBS CSI Driver IAM Role"
  value       = module.iam.ebs_csi_role_arn
}

output "iam_aws_lb_controller_role_arn" {
  description = "The ARN of the AWS Load Balancer Controller IAM Role"
  value       = module.iam.aws_lb_controller_role_arn
}

output "iam_cluster_autoscaler_role_arn" {
  description = "The ARN of the Cluster Autoscaler IAM Role"
  value       = module.iam.cluster_autoscaler_role_arn
}
