# ------------------------------------------------------------------------------
# Local Configuration for Phase Enablement & Application Parameters
# ------------------------------------------------------------------------------
locals {
  # ----------------------------------------------------------------------------
  # Phase Enablement Flags (Statically configured for Phase 1 - Cloud Foundation)
  # ----------------------------------------------------------------------------
  enable_ecr         = false
  enable_ecs         = false
  enable_alb         = false
  enable_codedeploy  = false
  enable_autoscaling = false

  # ----------------------------------------------------------------------------
  # Application Placeholders (Relocated from variables.tf)
  # ----------------------------------------------------------------------------
  mongo_uri    = "mongodb://dummy-placeholder"
  jwt_secret   = "dummy-secret"
  port         = 5000
  node_env     = "production"
  base_url     = "https://dummy-api.example.com"
  frontend_url = "https://dummy-frontend.example.com"
}

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

  # Production High Availability NAT setting (one NAT per AZ)
  enable_nat_gateway = true
  single_nat_gateway = false

  # HIPAA Flow Log Auditing
  enable_flow_logs         = true
  flow_logs_retention_days = 365 # 365 Days for Prod Compliance

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

# ==============================================================================
# Phase 2 - Container Registry
# ==============================================================================
module "ecr" {
  count  = local.enable_ecr ? 1 : 0
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ==============================================================================
# Phase 3 - ECS Platform
# ==============================================================================
module "ecs" {
  count  = local.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_node_sg_id]

  container_name   = "app-container"
  container_port   = 5000
  container_image  = local.enable_ecr ? "${module.ecr[0].repository_url}:latest" : "placeholder-image:latest"
  desired_count    = 2
  cpu              = 512
  memory           = 1024
  target_group_arn = local.enable_alb ? module.alb[0].alb_target_group_blue_arn : ""

  mongo_uri    = local.mongo_uri
  jwt_secret   = local.jwt_secret
  port         = local.port
  node_env     = local.node_env
  base_url     = local.base_url
  frontend_url = local.frontend_url

  alb_security_group_id = local.enable_alb ? module.alb[0].alb_security_group_id : ""
}

# ==============================================================================
# Phase 4 - Load Balancer
# ==============================================================================
module "alb" {
  count  = local.enable_alb ? 1 : 0
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# ==============================================================================
# Phase 5 - Deployment
# ==============================================================================
module "codedeploy" {
  count  = local.enable_codedeploy ? 1 : 0
  source = "../../modules/codedeploy"

  project_name            = var.project_name
  environment             = var.environment
  ecs_cluster_name        = local.enable_ecs ? module.ecs[0].ecs_cluster_name : ""
  ecs_service_name        = local.enable_ecs ? module.ecs[0].ecs_service_name : ""
  alb_listener_arn        = local.enable_alb ? module.alb[0].alb_listener_arn : ""
  blue_target_group_name  = local.enable_alb ? module.alb[0].alb_target_group_blue_name : ""
  green_target_group_name = local.enable_alb ? module.alb[0].alb_target_group_green_name : ""
}
