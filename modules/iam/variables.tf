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

# tflint-ignore: terraform_unused_declarations
variable "create_oidc_provider" {
  description = "Whether to create/use the OIDC provider (controls EKS/OIDC roles creation)"
  type        = bool
  default     = true
}

# IAM Policies Creation Feature Flags
variable "create_lb_controller_policy" {
  description = "Whether to create the IAM policy for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "create_cluster_autoscaler_policy" {
  description = "Whether to create the IAM policy for EKS Cluster Autoscaler"
  type        = bool
  default     = true
}

# IAM Policies Reuse Settings
variable "use_existing_lb_controller_policy" {
  description = "Whether to reuse an existing IAM policy for AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "existing_lb_controller_policy_arn" {
  description = "The ARN of the existing IAM policy for AWS Load Balancer Controller"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_lb_controller_policy_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:policy/.*$", var.existing_lb_controller_policy_arn))
    error_message = "The AWS Load Balancer Controller existing policy ARN must be a valid IAM policy ARN."
  }
}

variable "use_existing_cluster_autoscaler_policy" {
  description = "Whether to reuse an existing IAM policy for EKS Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "existing_cluster_autoscaler_policy_arn" {
  description = "The ARN of the existing IAM policy for EKS Cluster Autoscaler"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_cluster_autoscaler_policy_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:policy/.*$", var.existing_cluster_autoscaler_policy_arn))
    error_message = "The EKS Cluster Autoscaler existing policy ARN must be a valid IAM policy ARN."
  }
}

