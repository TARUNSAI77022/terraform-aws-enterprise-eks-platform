variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, stage, prod)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the EKS OIDC Provider for IRSA trust relationships"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "The URL of the EKS OIDC Provider for IRSA trust relationships"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the IAM roles"
  type        = map(string)
  default     = {}
}

variable "create_oidc_provider" {
  description = "Whether to create/use the OIDC provider (controls EKS/OIDC roles creation)"
  type        = bool
  default     = true
}
