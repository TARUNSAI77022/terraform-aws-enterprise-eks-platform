variable "cluster_name" {
  description = "The name of the EKS cluster to attach add-ons to"
  type        = string
}

variable "coredns_version" {
  description = "The version of the CoreDNS add-on to install"
  type        = string
  default     = ""
}

variable "kube_proxy_version" {
  description = "The version of the kube-proxy add-on to install"
  type        = string
  default     = ""
}

variable "vpc_cni_version" {
  description = "The version of the VPC CNI add-on to install"
  type        = string
  default     = ""
}

variable "enable_coredns" {
  description = "Whether to deploy the CoreDNS add-on"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Whether to deploy the kube-proxy add-on"
  type        = bool
  default     = true
}

variable "enable_vpc_cni" {
  description = "Whether to deploy the VPC CNI add-on"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the add-on resources"
  type        = map(string)
  default     = {}
}

