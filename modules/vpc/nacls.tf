# ------------------------------------------------------------------------------
# Public Subnets NACL
# ------------------------------------------------------------------------------
resource "aws_network_acl" "public" {
  #checkov:skip=CKV_AWS_231:NACL ephemeral port range allows return traffic for TCP connections and is stateless.
  #checkov:skip=CKV2_AWS_1:NACLs are explicitly attached to subnets using the subnet_ids attribute.
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-nacl-public"
    }
  )
}

# ------------------------------------------------------------------------------
# Private Application Subnets NACL
# ------------------------------------------------------------------------------
resource "aws_network_acl" "private" {
  #checkov:skip=CKV_AWS_231:NACL ephemeral port range allows return traffic for TCP connections and is stateless.
  #checkov:skip=CKV2_AWS_1:NACLs are explicitly attached to subnets using the subnet_ids attribute.
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Inbound Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-nacl-private"
    }
  )
}

# ------------------------------------------------------------------------------
# Private Database Subnets NACL (Strictly Local)
# ------------------------------------------------------------------------------
resource "aws_network_acl" "database" {
  #checkov:skip=CKV2_AWS_1:NACLs are explicitly attached to subnets using the subnet_ids attribute.
  count      = var.enable_database_networking ? 1 : 0
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Inbound: Allow port 5432 from within the VPC only
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 5432
    to_port    = 5432
  }

  # Outbound: Allow ephemeral ports back to internal VPC hosts only
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-nacl-database"
    }
  )
}

moved {
  from = aws_network_acl.database
  to   = aws_network_acl.database[0]
}
