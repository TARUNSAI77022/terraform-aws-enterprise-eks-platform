resource "aws_eks_addon" "coredns" {
  cluster_name  = var.cluster_name
  addon_name    = "coredns"
  addon_version = var.coredns_version

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-coredns"
    }
  )
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = var.cluster_name
  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_version

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-kube-proxy"
    }
  )

  depends_on = [aws_eks_addon.coredns]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = var.cluster_name
  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_version

  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-vpc-cni"
    }
  )

  depends_on = [aws_eks_addon.kube_proxy]
}
