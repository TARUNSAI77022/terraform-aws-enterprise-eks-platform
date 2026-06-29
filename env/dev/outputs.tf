output "vpc_id" {
  description = "The ID of the VPC"
  value       = var.enable_vpc ? module.vpc[0].vpc_id : null
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = var.enable_vpc ? module.vpc[0].vpc_cidr_block : null
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = var.enable_vpc ? module.vpc[0].public_subnet_ids : null
}

output "private_subnet_ids" {
  description = "The IDs of the private application subnets"
  value       = var.enable_vpc ? module.vpc[0].private_subnet_ids : null
}

output "database_subnet_ids" {
  description = "The IDs of the private database subnets"
  value       = var.enable_vpc ? module.vpc[0].database_subnet_ids : null
}

output "database_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = var.enable_vpc ? module.vpc[0].database_subnet_group_name : null
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = var.enable_vpc ? module.vpc[0].internet_gateway_id : null
}

output "nat_gateway_ips" {
  description = "The public Elastic IP addresses of the NAT Gateways"
  value       = var.enable_vpc ? module.vpc[0].nat_gateway_ips : null
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = var.enable_vpc ? module.vpc[0].nat_gateway_ids : null
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = var.enable_vpc ? module.vpc[0].public_route_table_id : null
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = var.enable_vpc ? module.vpc[0].private_route_table_ids : null
}

output "database_route_table_id" {
  description = "The ID of the database route table"
  value       = var.enable_vpc ? module.vpc[0].database_route_table_id : null
}

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------
output "alb_security_group_id" {
  description = "The ID of the ALB Security Group"
  value       = var.enable_alb ? module.alb[0].alb_security_group_id : null
}

output "app_node_security_group_id" {
  description = "The ID of the Unified Host Security Group"
  value       = var.enable_vpc ? module.security_groups[0].app_node_sg_id : null
}

output "ssm_bastion_security_group_id" {
  description = "The ID of the SSM Bastion Host Security Group"
  value       = var.enable_vpc ? module.security_groups[0].ssm_bastion_sg_id : null
}

output "database_security_group_id" {
  description = "The ID of the PostgreSQL Database Security Group"
  value       = var.enable_vpc ? module.security_groups[0].db_sg_id : null
}

output "eks_cluster_security_group_id" {
  description = "The ID of the EKS Cluster Control Plane Security Group"
  value       = var.enable_vpc ? module.security_groups[0].eks_cluster_sg_id : null
}

output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group securing the interface VPC endpoints"
  value       = var.enable_vpc ? module.vpc[0].vpc_endpoint_sg_id : null
}

# ------------------------------------------------------------------------------
# VPC Endpoint Outputs
# ------------------------------------------------------------------------------
output "vpc_endpoint_ids" {
  description = "A map of service key to VPC Endpoint ID for interface endpoints"
  value       = var.enable_vpc ? module.vpc[0].vpc_endpoint_ids : null
}

output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint"
  value       = var.enable_vpc ? module.vpc[0].s3_endpoint_id : null
}

# ------------------------------------------------------------------------------
# App and ECR Outputs
# ------------------------------------------------------------------------------
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = var.enable_alb ? module.alb[0].alb_dns_name : null
}

output "alb_target_group_blue_arn" {
  description = "The ARN of the Blue ALB Target Group"
  value       = var.enable_alb ? module.alb[0].alb_target_group_blue_arn : null
}

output "alb_target_group_green_arn" {
  description = "The ARN of the Green ALB Target Group"
  value       = var.enable_alb ? module.alb[0].alb_target_group_green_arn : null
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = var.enable_ecr ? module.ecr[0].repository_url : null
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].ecs_cluster_name : null
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = var.enable_ecs ? module.ecs[0].ecs_service_name : null
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy Application"
  value       = var.enable_codedeploy ? module.codedeploy[0].application_name : null
}

output "codedeploy_deployment_group" {
  description = "The name of the CodeDeploy Deployment Group"
  value       = var.enable_codedeploy ? module.codedeploy[0].deployment_group_name : null
}
