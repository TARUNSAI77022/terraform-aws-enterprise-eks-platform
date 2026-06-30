output "addon_arn" {
  description = "The ARN of the EBS CSI Driver EKS Add-on"
  value       = aws_eks_addon.ebs_csi.arn
}
