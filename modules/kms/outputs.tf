output "eks_kms_key_arn" {
  description = "The ARN of the KMS key for EKS secrets encryption"
  value       = aws_kms_key.eks.arn
}

output "cloudwatch_kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_key.cloudwatch.arn
}

output "ecr_kms_key_arn" {
  description = "The ARN of the KMS key for ECR repository encryption"
  value       = aws_kms_key.ecr.arn
}
