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
}

# ------------------------------------------------------------------------------
# Data Source to fetch VPC CIDR Block
# ------------------------------------------------------------------------------
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# ------------------------------------------------------------------------------
# 1. Application Load Balancer (ALB) Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  #checkov:skip=CKV_AWS_260:ALB is public-facing and port 80 is required to receive public HTTP traffic for redirection.
  #checkov:skip=CKV2_AWS_5:Security groups are designed to be attached to compute/database resources during subsequent deployment phases.
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for public Application Load Balancer"
  vpc_id      = var.vpc_id

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "Allow HTTP public traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "Allow HTTPS public traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  egress {
    description = "Allow outbound to application nodes within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. Unified Application Node Security Group (ECS, EKS, EC2 Compute)
# ------------------------------------------------------------------------------
resource "aws_security_group" "app_node_sg" {
  #checkov:skip=CKV2_AWS_5:Security groups are designed to be attached to compute/database resources during subsequent deployment phases.
  name        = "${var.project_name}-${var.environment}-app-node-sg"
  description = "Security group for compute nodes (ECS tasks, EKS workers, EC2)"
  vpc_id      = var.vpc_id

  # Inbound from public ALB
  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound self-reference for inter-node communication (e.g. EKS node-to-node or ECS container-to-container)
  ingress {
    description = "Allow internal inter-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound rules (Least privilege egress)
  egress {
    description = "Allow internal communication within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow HTTPS outbound to internet for updates and AWS APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow HTTP outbound to internet for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-app-node-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. Systems Manager (SSM) Bastion Host Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "ssm_bastion_sg" {
  #checkov:skip=CKV2_AWS_5:Security groups are designed to be attached to compute/database resources during subsequent deployment phases.
  name        = "${var.project_name}-${var.environment}-ssm-bastion-sg"
  description = "Security group for Bastion Host using SSM Session Manager"
  vpc_id      = var.vpc_id

  # No ingress ports open! (SSM Agent makes outbound connections only)

  egress {
    description = "Allow outbound internal communication within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow HTTPS outbound to SSM endpoints and AWS APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow HTTP outbound to internet for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-ssm-bastion-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 4. PostgreSQL RDS Database Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "db_sg" {
  #checkov:skip=CKV2_AWS_5:Security groups are designed to be attached to compute/database resources during subsequent deployment phases.
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for private PostgreSQL database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access from Application Nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_node_sg.id]
  }

  ingress {
    description     = "Allow PostgreSQL access from SSM Bastion Host"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_bastion_sg.id]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 5. EKS Control Plane Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  #checkov:skip=CKV2_AWS_5:Security groups are designed to be attached to compute/database resources during subsequent deployment phases.
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for future Amazon EKS Control Plane"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from Application Node workers"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_node_sg.id]
  }

  egress {
    description     = "Allow control plane to communicate with Node group workers"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.app_node_sg.id]
  }

  egress {
    description     = "Allow control plane to reach nodes on HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_node_sg.id]
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
    }
  )
}
