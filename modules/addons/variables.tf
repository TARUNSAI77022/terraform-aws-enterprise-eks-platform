variable "cluster_name" {
  description = "The name of the EKS cluster to attach add-ons to"
  type        = string
}

variable "coredns_version" {
  description = "The version of the CoreDNS add-on to install"
  type        = string
}

variable "kube_proxy_version" {
  description = "The version of the kube-proxy add-on to install"
  type        = string
}

variable "vpc_cni_version" {
  description = "The version of the VPC CNI add-on to install"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the add-on resources"
  type        = map(string)
  default     = {}
}
