variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, stage, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the KMS keys"
  type        = map(string)
  default     = {}
}

# KMS Creation Feature Flags
variable "create_eks_kms" {
  description = "Whether to create the KMS key for EKS secrets envelope encryption"
  type        = bool
  default     = true
}

variable "create_cloudwatch_kms" {
  description = "Whether to create the KMS key for CloudWatch Logs encryption"
  type        = bool
  default     = true
}

variable "create_ecr_kms" {
  description = "Whether to create the KMS key for ECR repository encryption"
  type        = bool
  default     = true
}

# KMS Reuse Settings
variable "use_existing_eks_kms" {
  description = "Whether to reuse an existing KMS key for EKS secrets envelope encryption"
  type        = bool
  default     = false
}

variable "existing_eks_kms_alias" {
  description = "The alias of the existing KMS key for EKS secrets envelope encryption (must start with 'alias/')"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_eks_kms_alias == "" || startswith(var.existing_eks_kms_alias, "alias/")
    error_message = "The EKS KMS key alias must start with 'alias/'."
  }
}

variable "use_existing_cloudwatch_kms" {
  description = "Whether to reuse an existing KMS key for CloudWatch Logs encryption"
  type        = bool
  default     = false
}

variable "existing_cloudwatch_kms_alias" {
  description = "The alias of the existing KMS key for CloudWatch Logs encryption (must start with 'alias/')"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_cloudwatch_kms_alias == "" || startswith(var.existing_cloudwatch_kms_alias, "alias/")
    error_message = "The CloudWatch KMS key alias must start with 'alias/'."
  }
}

variable "use_existing_ecr_kms" {
  description = "Whether to reuse an existing KMS key for ECR repository encryption"
  type        = bool
  default     = false
}

variable "existing_ecr_kms_alias" {
  description = "The alias of the existing KMS key for ECR repository encryption (must start with 'alias/')"
  type        = string
  default     = ""

  validation {
    condition     = var.existing_ecr_kms_alias == "" || startswith(var.existing_ecr_kms_alias, "alias/")
    error_message = "The ECR KMS key alias must start with 'alias/'."
  }
}

