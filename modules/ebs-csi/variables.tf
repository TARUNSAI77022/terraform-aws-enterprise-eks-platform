variable "cluster_name" {
  description = "The name of the EKS cluster to attach the EBS CSI add-on to"
  type        = string
}

variable "ebs_csi_version" {
  description = "The version of the EBS CSI driver add-on to install"
  type        = string
}

variable "irsa_role_arn" {
  description = "The ARN of the IAM role to use for the EBS CSI Driver Service Account (IRSA)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the add-on resources"
  type        = map(string)
  default     = {}
}
