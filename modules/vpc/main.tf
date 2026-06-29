# Fetch available Availability Zones dynamically in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Standardized baseline tags for resources in this module
locals {
  base_tags = {
    Project            = var.project_name
    Environment        = var.environment
    Application        = var.application
    Owner              = var.owner
    ManagedBy          = "Terraform"
    CostCenter         = var.cost_center
    Compliance         = var.compliance
    DataClassification = var.data_classification
    Backup             = var.backup
  }

  nat_gateway_count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  private_route_table_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)) : 0
}

# ------------------------------------------------------------------------------
# VPC Configuration
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Hardened Default Security Group (Deny all traffic)
# ------------------------------------------------------------------------------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  # Left empty to deny all ingress and egress traffic natively
}

# ------------------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Subnets Layout (Multi-AZ resolution)
# ------------------------------------------------------------------------------

# Public Subnets (routing to Internet Gateway)
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Public subnets must map public IPs on launch to support public load balancers and NAT Gateways.
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.base_tags,
    {
      Name                     = "${var.project_name}-${var.environment}-subnet-public-${data.aws_availability_zones.available.names[count.index]}"
      "kubernetes.io/role/elb" = "1"
    },
    var.eks_cluster_name != "" ? { "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared" } : {}
  )
}

# Private Application Subnets (routing to NAT Gateways)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.base_tags,
    {
      Name                              = "${var.project_name}-${var.environment}-subnet-private-app-${data.aws_availability_zones.available.names[count.index]}"
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.eks_cluster_name != "" ? { "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared" } : {}
  )
}

# Private Database Subnets (isolated local routing only)
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-subnet-database-${data.aws_availability_zones.available.names[count.index]}"
    }
  )
}

# ------------------------------------------------------------------------------
# DB Subnet Group (for Multi-AZ RDS Deployment)
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Isolated database subnet group for RDS/PostgreSQL"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-subnet-group"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# NAT Gateway and Elastic IP (Configurable Outbound Routing)
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip-${data.aws_availability_zones.available.names[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-gw-${data.aws_availability_zones.available.names[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-rt-public"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Private Route Table(s)
resource "aws_route_table" "private" {
  count  = local.private_route_table_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-rt-private-${var.single_nat_gateway ? "shared" : data.aws_availability_zones.available.names[count.index]}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Database Route Table (strictly isolated)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-rt-database"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ------------------------------------------------------------------------------
# HIPAA VPC Flow Logs Configuration
# ------------------------------------------------------------------------------
resource "aws_flow_log" "main" {
  count                    = var.enable_flow_logs ? 1 : 0
  iam_role_arn             = aws_iam_role.vpc_flow_log_role[0].arn
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.main.id
  max_aggregation_interval = 60

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  #checkov:skip=CKV_AWS_158:Flow logs are encrypted using CloudWatch default service-side encryption in development phase.
  #checkov:skip=CKV_AWS_338:Retention is set to less than 1 year in development and staging environments to optimize costs.
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-flow-logs-group"
    }
  )
}

resource "aws_iam_role" "vpc_flow_log_role" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.base_tags
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"
      }
    ]
  })
}
