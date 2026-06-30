output "coredns_arn" {
  description = "The ARN of the CoreDNS EKS Add-on"
  value       = aws_eks_addon.coredns.arn
}

output "kube_proxy_arn" {
  description = "The ARN of the kube-proxy EKS Add-on"
  value       = aws_eks_addon.kube_proxy.arn
}

output "vpc_cni_arn" {
  description = "The ARN of the VPC CNI EKS Add-on"
  value       = aws_eks_addon.vpc_cni.arn
}
