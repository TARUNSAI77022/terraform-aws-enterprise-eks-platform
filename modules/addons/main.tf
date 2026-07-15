resource "aws_eks_addon" "coredns" {
  count         = var.enable_coredns ? 1 : 0
  cluster_name  = var.cluster_name
  addon_name    = "coredns"
  addon_version = var.coredns_version != "" ? var.coredns_version : null

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-coredns"
    }
  )
}

resource "aws_eks_addon" "kube_proxy" {
  count         = var.enable_kube_proxy ? 1 : 0
  cluster_name  = var.cluster_name
  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_version != "" ? var.kube_proxy_version : null

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-addon-kube-proxy"
    }
  )

  depends_on = [aws_eks_addon.coredns]
}

resource "aws_eks_addon" "vpc_cni" {
  count         = var.enable_vpc_cni ? 1 : 0
  cluster_name  = var.cluster_name
  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_version != "" ? var.vpc_cni_version : null

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
}
