output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private application subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "The IDs of the private database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = aws_db_subnet_group.database.name
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_ips" {
  description = "The public Elastic IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = aws_nat_gateway.nat[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "The ID of the database route table"
  value       = aws_route_table.database.id
}

output "vpc_endpoint_sg_id" {
  description = "The ID of the security group securing the interface VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_endpoint_ids" {
  description = "A map of service key to VPC Endpoint ID for interface endpoints"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}
