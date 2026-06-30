variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, stage, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "The ARN of the IAM role for the EKS node group"
  type        = string
}

variable "subnet_ids" {
  description = "A list of private subnet IDs where nodes will be launched"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "The ID of the security group to assign to the worker nodes (app_node_sg)"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS Customer Managed Key to encrypt node EBS root volumes"
  type        = string
}

variable "node_groups" {
  description = "A map of EKS Managed Node Group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD") # e.g. BOTTLEROCKET_x86_64 or AL2023_x86_64_STANDARD
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    update_config = optional(object({
      max_unavailable            = optional(number)
      max_unavailable_percentage = optional(number)
    }), { max_unavailable = 1 })
  }))
}

variable "tags" {
  description = "A map of tags to assign to the node group resources"
  type        = map(string)
  default     = {}
}
