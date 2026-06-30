resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.chart_version

  # Pass tags to helm values to avoid unused variable warning
  values = [
    jsonencode({
      additionalTags = var.tags
    })
  ]

  # Best practice configurations for HA and reliability
  set {
    name  = "apiService.create"
    value = "true"
  }
}
