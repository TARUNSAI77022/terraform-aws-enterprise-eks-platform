variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "irsa_role_arn" {
  description = "The ARN of the IAM role to associate with the cluster autoscaler service account"
  type        = string
}

variable "aws_region" {
  description = "The AWS Region where the cluster is deployed"
  type        = string
}

variable "chart_version" {
  description = "The Helm chart version to install"
  type        = string
  default     = "9.37.0"
}
