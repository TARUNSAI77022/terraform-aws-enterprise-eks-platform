# ------------------------------------------------------------------------------
# 1. Enterprise VPC Module (Foundation)
# ------------------------------------------------------------------------------
module "vpc" {
  count  = var.enable_vpc ? 1 : 0
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
# 2. Enterprise Security Groups Module
# ------------------------------------------------------------------------------
module "security_groups" {
  count  = var.enable_vpc ? 1 : 0
  source = "../../modules/security-groups"

  vpc_id                  = module.vpc[0].vpc_id
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

# ------------------------------------------------------------------------------
# 3. Application Load Balancer Module
# ------------------------------------------------------------------------------
module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = var.enable_vpc ? module.vpc[0].vpc_id : ""
  public_subnet_ids = var.enable_vpc ? module.vpc[0].public_subnet_ids : []
}

# ------------------------------------------------------------------------------
# 4. ECR Repository Module
# ------------------------------------------------------------------------------
module "ecr" {
  count  = var.enable_ecr ? 1 : 0
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 5. ECS Compute Module
# ------------------------------------------------------------------------------
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = var.enable_vpc ? module.vpc[0].vpc_id : ""

  # ECS tasks run securely in private subnets
  private_subnet_ids = var.enable_vpc ? module.vpc[0].private_subnet_ids : []

  # Bind to the central unified application security group
  security_group_ids = var.enable_vpc ? [module.security_groups[0].app_node_sg_id] : []

  container_name   = "app-container"
  container_port   = 5000
  container_image  = var.enable_ecr ? "${module.ecr[0].repository_url}:latest" : "placeholder-image:latest"
  desired_count    = 2
  cpu              = 512
  memory           = 1024
  target_group_arn = var.enable_alb ? module.alb[0].alb_target_group_blue_arn : ""

  mongo_uri    = var.mongo_uri
  jwt_secret   = var.jwt_secret
  port         = var.port
  node_env     = var.node_env
  base_url     = var.base_url
  frontend_url = var.frontend_url

  # Backward compatible parameter
  alb_security_group_id = var.enable_alb ? module.alb[0].alb_security_group_id : ""
}

# ------------------------------------------------------------------------------
# 6. Blue/Green CodeDeploy Deployment Module
# ------------------------------------------------------------------------------
module "codedeploy" {
  count  = var.enable_codedeploy ? 1 : 0
  source = "../../modules/codedeploy"

  project_name            = var.project_name
  environment             = var.environment
  ecs_cluster_name        = var.enable_ecs ? module.ecs[0].ecs_cluster_name : ""
  ecs_service_name        = var.enable_ecs ? module.ecs[0].ecs_service_name : ""
  alb_listener_arn        = var.enable_alb ? module.alb[0].alb_listener_arn : ""
  blue_target_group_name  = var.enable_alb ? module.alb[0].alb_target_group_blue_name : ""
  green_target_group_name = var.enable_alb ? module.alb[0].alb_target_group_green_name : ""
}
