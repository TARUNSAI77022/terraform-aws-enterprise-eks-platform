resource "aws_cloudwatch_log_group" "eks" {
  # checkov:skip=CKV_AWS_338:Short retention is preferred for cost-saving in non-prod environments
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name = "/aws/eks/${var.cluster_name}/cluster"
    }
  )
}
