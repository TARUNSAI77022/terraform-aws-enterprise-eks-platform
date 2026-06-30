resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_version
  service_account_role_arn = var.irsa_role_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-aws-ebs-csi-driver"
    }
  )
}
