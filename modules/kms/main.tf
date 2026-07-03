data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 1. EKS Secrets Encryption Key
resource "aws_kms_key" "eks" {
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
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# 2. CloudWatch Logs Encryption Key
resource "aws_kms_key" "cloudwatch" {
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
  name          = "alias/${var.project_name}-${var.environment}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# 3. Amazon ECR Encryption Key
resource "aws_kms_key" "ecr" {
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
  name          = "alias/${var.project_name}-${var.environment}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
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
    sid    = "AllowAutoScalingToUseKey"
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
    }
  }

  statement {
    sid    = "AllowAutoScalingToCreateGrants"
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
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
