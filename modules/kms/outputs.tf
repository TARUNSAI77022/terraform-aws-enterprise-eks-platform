output "eks_kms_key_arn" {
  description = "The ARN of the KMS key for EKS secrets encryption"
  value       = local.eks_kms_key_arn
}

output "cloudwatch_kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Logs encryption"
  value       = local.cloudwatch_kms_key_arn
}

output "ecr_kms_key_arn" {
  description = "The ARN of the KMS key for ECR repository encryption"
  value       = local.ecr_kms_key_arn
}

