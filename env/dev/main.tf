# ------------------------------------------------------------------------------
# 1. Enterprise VPC Module (Foundation - Phase 1)
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  # Dev budget-friendly NAT gateway setting
  enable_nat_gateway = true
  single_nat_gateway = true

  # HIPAA Flow Log Auditing
  enable_flow_logs         = true
  flow_logs_retention_days = 30 # 30 Days for Dev

  # Integrations
  eks_cluster_name = "${var.project_name}-${var.environment}-eks"

  # Standard Tagging Parameters
  application         = var.application
  owner               = var.owner
  cost_center         = var.cost_center
  compliance          = var.compliance
  data_classification = var.data_classification
  backup              = var.backup
}

# ------------------------------------------------------------------------------
# 2. Enterprise Security Groups Module (Foundation - Phase 1)
# ------------------------------------------------------------------------------
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id                  = module.vpc.vpc_id
  project_name            = var.project_name
  environment             = var.environment
  alb_ingress_cidr_blocks = var.alb_ingress_cidr_blocks

  # Standard Tagging Parameters
  application         = var.application
  owner               = var.owner
  cost_center         = var.cost_center
  compliance          = var.compliance
  data_classification = var.data_classification
  backup              = var.backup
}
