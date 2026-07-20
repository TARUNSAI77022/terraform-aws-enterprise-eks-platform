data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# 0. Data Sources for Existing KMS Keys
# ------------------------------------------------------------------------------
data "aws_kms_alias" "eks" {
  count = var.use_existing_eks_kms ? 1 : 0
  name  = var.existing_eks_kms_alias
}

data "aws_kms_alias" "cloudwatch" {
  count = var.use_existing_cloudwatch_kms ? 1 : 0
  name  = var.existing_cloudwatch_kms_alias
}

data "aws_kms_alias" "ecr" {
  count = var.use_existing_ecr_kms ? 1 : 0
  name  = var.existing_ecr_kms_alias
}

# ------------------------------------------------------------------------------
# 0b. Validation Preconditions
# ------------------------------------------------------------------------------
resource "terraform_data" "validate_eks_kms_config" {
  lifecycle {
    precondition {
      condition     = !(var.create_eks_kms && var.use_existing_eks_kms)
      error_message = "Conflicting config: create_eks_kms and use_existing_eks_kms cannot both be true."
    }
    precondition {
      condition     = var.create_eks_kms || var.use_existing_eks_kms
      error_message = "Invalid config: At least one of create_eks_kms or use_existing_eks_kms must be true."
    }
    precondition {
      condition     = !var.use_existing_eks_kms || (var.existing_eks_kms_alias != null && var.existing_eks_kms_alias != "")
      error_message = "Invalid config: existing_eks_kms_alias must be provided when use_existing_eks_kms is true."
    }
  }
}

resource "terraform_data" "validate_cloudwatch_kms_config" {
  lifecycle {
    precondition {
      condition     = !(var.create_cloudwatch_kms && var.use_existing_cloudwatch_kms)
      error_message = "Conflicting config: create_cloudwatch_kms and use_existing_cloudwatch_kms cannot both be true."
    }
    precondition {
      condition     = var.create_cloudwatch_kms || var.use_existing_cloudwatch_kms
      error_message = "Invalid config: At least one of create_cloudwatch_kms or use_existing_cloudwatch_kms must be true."
    }
    precondition {
      condition     = !var.use_existing_cloudwatch_kms || (var.existing_cloudwatch_kms_alias != null && var.existing_cloudwatch_kms_alias != "")
      error_message = "Invalid config: existing_cloudwatch_kms_alias must be provided when use_existing_cloudwatch_kms is true."
    }
  }
}

resource "terraform_data" "validate_ecr_kms_config" {
  lifecycle {
    precondition {
      condition     = !(var.create_ecr_kms && var.use_existing_ecr_kms)
      error_message = "Conflicting config: create_ecr_kms and use_existing_ecr_kms cannot both be true."
    }
    precondition {
      condition     = var.create_ecr_kms || var.use_existing_ecr_kms
      error_message = "Invalid config: At least one of create_ecr_kms or use_existing_ecr_kms must be true."
    }
    precondition {
      condition     = !var.use_existing_ecr_kms || (var.existing_ecr_kms_alias != null && var.existing_ecr_kms_alias != "")
      error_message = "Invalid config: existing_ecr_kms_alias must be provided when use_existing_ecr_kms is true."
    }
  }
}

# ------------------------------------------------------------------------------
# 0c. Local Variables for Resolved Key ARNs
# ------------------------------------------------------------------------------
locals {
  eks_kms_key_arn        = var.use_existing_eks_kms ? data.aws_kms_alias.eks[0].target_key_arn : aws_kms_key.eks[0].arn
  cloudwatch_kms_key_arn = var.use_existing_cloudwatch_kms ? data.aws_kms_alias.cloudwatch[0].target_key_arn : aws_kms_key.cloudwatch[0].arn
  ecr_kms_key_arn        = var.use_existing_ecr_kms ? data.aws_kms_alias.ecr[0].target_key_arn : aws_kms_key.ecr[0].arn
}

# ------------------------------------------------------------------------------
# 0d. State Migration Moved Blocks
# ------------------------------------------------------------------------------
moved {
  from = aws_kms_key.eks
  to   = aws_kms_key.eks[0]
}

moved {
  from = aws_kms_alias.eks
  to   = aws_kms_alias.eks[0]
}

moved {
  from = aws_kms_key.cloudwatch
  to   = aws_kms_key.cloudwatch[0]
}

moved {
  from = aws_kms_alias.cloudwatch
  to   = aws_kms_alias.cloudwatch[0]
}

moved {
  from = aws_kms_key.ecr
  to   = aws_kms_key.ecr[0]
}

moved {
  from = aws_kms_alias.ecr
  to   = aws_kms_alias.ecr[0]
}

# 1. EKS Secrets Encryption Key
resource "aws_kms_key" "eks" {
  count                   = (var.create_eks_kms && !var.use_existing_eks_kms) ? 1 : 0
  description             = "KMS Key for EKS Secrets Envelope Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.default.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-kms-eks"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count         = (var.create_eks_kms && !var.use_existing_eks_kms) ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# 2. CloudWatch Logs Encryption Key
resource "aws_kms_key" "cloudwatch" {
  count                   = (var.create_cloudwatch_kms && !var.use_existing_cloudwatch_kms) ? 1 : 0
  description             = "KMS Key for CloudWatch Logs Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-kms-cloudwatch"
    }
  )
}

resource "aws_kms_alias" "cloudwatch" {
  count         = (var.create_cloudwatch_kms && !var.use_existing_cloudwatch_kms) ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch[0].key_id
}

# 3. Amazon ECR Encryption Key
resource "aws_kms_key" "ecr" {
  count                   = (var.create_ecr_kms && !var.use_existing_ecr_kms) ? 1 : 0
  description             = "KMS Key for ECR Repositories Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.default.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-kms-ecr"
    }
  )
}

resource "aws_kms_alias" "ecr" {
  count         = (var.create_ecr_kms && !var.use_existing_ecr_kms) ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-ecr"
  target_key_id = aws_kms_key.ecr[0].key_id
}


# ------------------------------------------------------------------------------
# IAM Policy Documents for KMS Keys
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "default" {
  # checkov:skip=CKV_AWS_109:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  # checkov:skip=CKV_AWS_111:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  # checkov:skip=CKV_AWS_356:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowEKSAndAutoScalingToUseKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-eks-cluster-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-eks-node-role"
      ]
    }
  }

  statement {
    sid    = "AllowEKSAndAutoScalingToCreateGrants"
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-eks-cluster-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-eks-node-role"
      ]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid    = "AllowServicesToUseKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
        "ec2.amazonaws.com",
        "autoscaling.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowServicesToCreateGrants"
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
        "ec2.amazonaws.com",
        "autoscaling.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  # checkov:skip=CKV_AWS_109:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  # checkov:skip=CKV_AWS_111:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  # checkov:skip=CKV_AWS_356:KMS key policies require wildcard resource (*) and root account full management access per AWS best practice
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}
