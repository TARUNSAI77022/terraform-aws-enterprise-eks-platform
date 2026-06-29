# ------------------------------------------------------------------------------
# 1. Enterprise VPC Module (Foundation)
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  # Staging budget-friendly NAT gateway setting
  enable_nat_gateway = true
  single_nat_gateway = true

  # HIPAA Flow Log Auditing
  enable_flow_logs         = true
  flow_logs_retention_days = 90 # 90 Days for Stage

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
# 2. Enterprise Security Groups Module
# ------------------------------------------------------------------------------
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment

  # Standard Tagging Parameters
  application         = var.application
  owner               = var.owner
  cost_center         = var.cost_center
  compliance          = var.compliance
  data_classification = var.data_classification
  backup              = var.backup
}

# ------------------------------------------------------------------------------
# 3. Application Load Balancer Module
# ------------------------------------------------------------------------------
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# ------------------------------------------------------------------------------
# 4. ECR Repository Module
# ------------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 5. ECS Compute Module
# ------------------------------------------------------------------------------
module "ecs" {
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  # ECS tasks run securely in private subnets
  private_subnet_ids = module.vpc.private_subnet_ids

  # Bind to the central unified application security group
  security_group_ids = [module.security_groups.app_node_sg_id]

  container_name   = "app-container"
  container_port   = 5000
  container_image  = "${module.ecr.repository_url}:latest"
  desired_count    = 2
  cpu              = 512
  memory           = 1024
  target_group_arn = module.alb.alb_target_group_blue_arn

  mongo_uri    = var.mongo_uri
  jwt_secret   = var.jwt_secret
  port         = var.port
  node_env     = var.node_env
  base_url     = var.base_url
  frontend_url = var.frontend_url

  # Backward compatible parameter
  alb_security_group_id = module.alb.alb_security_group_id
}

# ------------------------------------------------------------------------------
# 6. Blue/Green CodeDeploy Deployment Module
# ------------------------------------------------------------------------------
module "codedeploy" {
  source = "../../modules/codedeploy"

  project_name            = var.project_name
  environment             = var.environment
  ecs_cluster_name        = module.ecs.ecs_cluster_name
  ecs_service_name        = module.ecs.ecs_service_name
  alb_listener_arn        = module.alb.alb_listener_arn
  blue_target_group_name  = module.alb.alb_target_group_blue_name
  green_target_group_name = module.alb.alb_target_group_green_name
}
