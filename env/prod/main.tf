# ------------------------------------------------------------------------------
# Local Tags Helper
# ------------------------------------------------------------------------------
locals {
  tags = {
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
# 1. Enterprise VPC Module (Foundation - Phase 1)
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project_name               = var.project_name
  environment                = var.environment
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_subnet_cidrs       = var.private_subnet_cidrs
  database_subnet_cidrs      = var.database_subnet_cidrs
  enable_database_networking = var.enable_database_networking

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

  vpc_id                     = module.vpc.vpc_id
  project_name               = var.project_name
  environment                = var.environment
  alb_ingress_cidr_blocks    = var.alb_ingress_cidr_blocks
  enable_database_networking = var.enable_database_networking

  # Standard Tagging Parameters
  application         = var.application
  owner               = var.owner
  cost_center         = var.cost_center
  compliance          = var.compliance
  data_classification = var.data_classification
  backup              = var.backup
}

# ------------------------------------------------------------------------------
# 3. Centralized KMS Management Module (Phase 2)
# ------------------------------------------------------------------------------
module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags

  create_eks_kms                = var.create_eks_kms
  create_cloudwatch_kms         = var.create_cloudwatch_kms
  create_ecr_kms                = var.create_ecr_kms
  use_existing_eks_kms          = var.use_existing_eks_kms
  existing_eks_kms_alias        = var.existing_eks_kms_alias
  use_existing_cloudwatch_kms   = var.use_existing_cloudwatch_kms
  existing_cloudwatch_kms_alias = var.existing_cloudwatch_kms_alias
  use_existing_ecr_kms          = var.use_existing_ecr_kms
  existing_ecr_kms_alias        = var.existing_ecr_kms_alias
}

# ------------------------------------------------------------------------------
# 4. Consolidated IAM Roles Module (Phase 2)
# ------------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  project_name         = var.project_name
  environment          = var.environment
  create_oidc_provider = var.create_oidc_provider
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  tags                 = local.tags

  create_lb_controller_policy            = var.create_lb_controller_policy
  create_cluster_autoscaler_policy       = var.create_cluster_autoscaler_policy
  use_existing_lb_controller_policy      = var.use_existing_lb_controller_policy
  existing_lb_controller_policy_arn      = var.existing_lb_controller_policy_arn
  use_existing_cluster_autoscaler_policy = var.use_existing_cluster_autoscaler_policy
  existing_cluster_autoscaler_policy_arn = var.existing_cluster_autoscaler_policy_arn
}

# ------------------------------------------------------------------------------
# 5. CloudWatch Audit Logs Module (Phase 2)
# ------------------------------------------------------------------------------
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  cluster_name   = "${var.project_name}-${var.environment}-eks"
  retention_days = 365 # Prod standard
  kms_key_arn    = module.kms.cloudwatch_kms_key_arn
  tags           = local.tags
}

# ------------------------------------------------------------------------------
# 6. Microservices ECR Repository Module (Phase 2)
# ------------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  project_name     = var.project_name
  environment      = var.environment
  repository_names = ["devops"]
  kms_key_arn      = module.kms.ecr_kms_key_arn
  tags             = local.tags
}

# ------------------------------------------------------------------------------
# 7. EKS Control Plane Module (Phase 2)
# ------------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  project_name               = var.project_name
  environment                = var.environment
  cluster_name               = "${var.project_name}-${var.environment}-eks"
  kubernetes_version         = var.kubernetes_version
  cluster_role_arn           = module.iam.eks_cluster_role_arn
  subnet_ids                 = module.vpc.private_subnet_ids
  security_group_ids         = [module.security_groups.eks_cluster_sg_id]
  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  public_access_cidrs        = var.public_access_cidrs
  kms_key_arn                = module.kms.eks_kms_key_arn
  create_oidc_provider       = var.create_oidc_provider
  oidc_provider_arn          = var.oidc_provider_arn
  oidc_provider_url          = var.oidc_provider_url
  authentication_mode        = var.authentication_mode
  access_entries             = var.access_entries
  tags                       = local.tags
  node_role_arn              = module.iam.node_group_role_arn
  create_caller_access_entry = true

  depends_on = [module.cloudwatch]
}

# ------------------------------------------------------------------------------
# 8. EKS Managed Node Groups Module (Phase 2)
# ------------------------------------------------------------------------------
module "node_groups" {
  source = "../../modules/eks-node-group"

  project_name           = var.project_name
  environment            = var.environment
  cluster_name           = module.eks.cluster_name
  node_role_arn          = module.iam.node_group_role_arn
  subnet_ids             = module.vpc.private_subnet_ids
  node_security_group_id = module.security_groups.app_node_sg_id
  kms_key_arn            = module.kms.eks_kms_key_arn
  node_groups            = var.node_groups
  tags                   = local.tags

  depends_on = [module.vpc_cni]
}

# ------------------------------------------------------------------------------
# 9a. Bootstrap EKS Add-ons (Phase 2 - Before Node Groups)
# ------------------------------------------------------------------------------
module "vpc_cni" {
  source = "../../modules/addons"

  cluster_name    = module.eks.cluster_name
  vpc_cni_version = var.vpc_cni_version
  tags            = local.tags

  enable_vpc_cni    = true
  enable_coredns    = false
  enable_kube_proxy = false

  depends_on = [module.eks]
}

# ------------------------------------------------------------------------------
# 9b. Runtime EKS Add-ons (Phase 2 - After Node Groups)
# ------------------------------------------------------------------------------
module "addons" {
  source = "../../modules/addons"

  cluster_name       = module.eks.cluster_name
  coredns_version    = var.coredns_version
  kube_proxy_version = var.kube_proxy_version
  tags               = local.tags

  enable_vpc_cni    = false
  enable_coredns    = true
  enable_kube_proxy = true

  depends_on = [module.node_groups]
}

# ------------------------------------------------------------------------------
# 10. Amazon EBS CSI Driver Module (Phase 2)
# ------------------------------------------------------------------------------
module "ebs_csi" {
  source = "../../modules/ebs-csi"

  cluster_name    = module.eks.cluster_name
  ebs_csi_version = var.ebs_csi_version
  irsa_role_arn   = module.iam.ebs_csi_role_arn
  tags            = local.tags

  depends_on = [module.node_groups, module.addons]
}

# ------------------------------------------------------------------------------
# 11. Kubernetes Metrics Server Module (Phase 2)
# ------------------------------------------------------------------------------
module "metrics_server" {
  source = "../../modules/metrics-server"

  enable        = true
  chart_version = var.metrics_server_version
  tags          = local.tags

  depends_on = [module.ebs_csi, module.addons]
}

# ------------------------------------------------------------------------------
# 12. AWS Load Balancer Controller Module (Phase 2)
# ------------------------------------------------------------------------------
module "aws_load_balancer_controller" {
  source = "../../modules/aws-load-balancer-controller"

  cluster_name  = module.eks.cluster_name
  irsa_role_arn = module.iam.aws_lb_controller_role_arn
  aws_region    = var.aws_region
  vpc_id        = module.vpc.vpc_id
  chart_version = var.aws_load_balancer_controller_version

  depends_on = [module.metrics_server, module.addons]
}

# ------------------------------------------------------------------------------
# 13. Cluster Autoscaler Module (Phase 2)
# ------------------------------------------------------------------------------
module "cluster_autoscaler" {
  source = "../../modules/cluster-autoscaler"

  cluster_name  = module.eks.cluster_name
  irsa_role_arn = module.iam.cluster_autoscaler_role_arn
  aws_region    = var.aws_region
  chart_version = var.cluster_autoscaler_version

  depends_on = [module.aws_load_balancer_controller]
}

# ------------------------------------------------------------------------------
# Placeholder Scaffolded Modules (Preparation for future phases)
# ------------------------------------------------------------------------------
module "security_scaffold" {
  source = "../../modules/security"
}

module "karpenter_scaffold" {
  source = "../../modules/karpenter"
}

module "external_secrets_scaffold" {
  source = "../../modules/external-secrets"
}

module "velero_scaffold" {
  source = "../../modules/velero"
}

module "monitoring_scaffold" {
  source = "../../modules/monitoring"
}

# ------------------------------------------------------------------------------
# State Migration Moved Blocks (Idempotent Lifecycle Management)
# ------------------------------------------------------------------------------
moved {
  from = module.addons.aws_eks_addon.coredns
  to   = module.addons.aws_eks_addon.coredns[0]
}

moved {
  from = module.addons.aws_eks_addon.kube_proxy
  to   = module.addons.aws_eks_addon.kube_proxy[0]
}

moved {
  from = module.addons.aws_eks_addon.vpc_cni
  to   = module.vpc_cni.aws_eks_addon.vpc_cni[0]
}

