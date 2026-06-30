variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "irsa_role_arn" {
  description = "The ARN of the IAM Role associated with the load balancer controller service account"
  type        = string
}

variable "aws_region" {
  description = "The AWS Region where the cluster is deployed"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the cluster resources are running"
  type        = string
}

variable "chart_version" {
  description = "The Helm chart version to install"
  type        = string
  default     = "1.8.1"
}
