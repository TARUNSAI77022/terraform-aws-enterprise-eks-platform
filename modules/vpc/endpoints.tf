# Fetch current region context
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# VPC Endpoints Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  description = "Security group for private VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow outbound traffic within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# Gateway VPC Endpoints (S3)
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpce-s3"
    }
  )
}

# Collect all route table IDs (public, private, and database tables)
locals {
  all_route_table_ids = concat(
    [aws_route_table.public.id, aws_route_table.database.id],
    aws_route_table.private[*].id
  )
}

# Associate S3 endpoint with all public and private route tables
resource "aws_vpc_endpoint_route_table_association" "s3" {
  count           = length(local.all_route_table_ids)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = local.all_route_table_ids[count.index]
}

# ------------------------------------------------------------------------------
# Interface VPC Endpoints (ECR, CW Logs, Monitoring, STS, Secrets Manager, SSM)
# ------------------------------------------------------------------------------
locals {
  interface_services = {
    ecr_api        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    ecr_dkr        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    logs           = "com.amazonaws.${data.aws_region.current.name}.logs"
    monitoring     = "com.amazonaws.${data.aws_region.current.name}.monitoring"
    sts            = "com.amazonaws.${data.aws_region.current.name}.sts"
    secretsmanager = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
    ssm            = "com.amazonaws.${data.aws_region.current.name}.ssm"
    ssmmessages    = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
    ec2messages    = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
    # Future KMS endpoint can be added here in Phase 2
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_services
  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpce-${each.key}"
    }
  )
}
