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
output "alb_security_group_id" {
  description = "The ID of the ALB Security Group"
  value       = module.alb.alb_security_group_id
}

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
# App and ECR Outputs
# ------------------------------------------------------------------------------
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_target_group_blue_arn" {
  description = "The ARN of the Blue ALB Target Group"
  value       = module.alb.alb_target_group_blue_arn
}

output "alb_target_group_green_arn" {
  description = "The ARN of the Green ALB Target Group"
  value       = module.alb.alb_target_group_green_arn
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = module.ecs.ecs_service_name
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy Application"
  value       = module.codedeploy.application_name
}

output "codedeploy_deployment_group" {
  description = "The name of the CodeDeploy Deployment Group"
  value       = module.codedeploy.deployment_group_name
}
