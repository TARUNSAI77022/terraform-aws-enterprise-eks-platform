# tfsec:ignore:aws-eks-no-public-cluster-access
# tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(
    var.tags,
    {
      Name        = var.cluster_name
      Project     = var.project_name
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# OpenID Connect (OIDC) Provider
# ------------------------------------------------------------------------------
data "tls_certificate" "eks" {
  count = var.create_oidc_provider ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count           = var.create_oidc_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-oidc-provider"
      Project     = var.project_name
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Amazon EKS Access Entries (Modern Authentication Model)
# ------------------------------------------------------------------------------
resource "aws_eks_access_entry" "this" {
  for_each      = var.access_entries
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = lookup(each.value, "type", "STANDARD")
  user_name     = lookup(each.value, "user_name", null)
}

resource "aws_eks_access_policy_association" "this" {
  for_each      = { for k, v in var.access_entries : k => v if lookup(v, "policy_arn", null) != null }
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = each.value.policy_arn
  principal_arn = each.value.principal_arn

  access_scope {
    type       = lookup(each.value.access_scope, "type", "cluster")
    namespaces = lookup(each.value.access_scope, "namespaces", null)
  }

  depends_on = [aws_eks_access_entry.this]
}

# ------------------------------------------------------------------------------
# Automated Access Entries for Executing Principal and Worker Nodes
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  caller_arn          = data.aws_caller_identity.current.arn
  is_assumed_role     = can(regex("^arn:aws:sts::[0-9]+:assumed-role/", local.caller_arn))
  account_id          = data.aws_caller_identity.current.account_id
  role_name           = local.is_assumed_role ? split("/", split("assumed-role/", local.caller_arn)[1])[0] : ""
  resolved_caller_arn = local.is_assumed_role ? "arn:aws:iam::${local.account_id}:role/${local.role_name}" : local.caller_arn
}

resource "aws_eks_access_entry" "caller" {
  count         = var.create_caller_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = local.resolved_caller_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "caller" {
  count         = var.create_caller_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.resolved_caller_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.caller]
}

resource "aws_eks_access_entry" "node_group" {
  count         = var.enable_node_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.node_role_arn
  type          = "EC2_LINUX"
}

