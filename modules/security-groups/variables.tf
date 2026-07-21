variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "The vpc_id must be a valid AWS VPC identifier starting with 'vpc-'."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name)) && length(var.project_name) > 0
    error_message = "The project name must be a non-empty alphanumeric string (hyphens are allowed)."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "The environment must be one of: dev, stage, prod."
  }
}

# ------------------------------------------------------------------------------
# Reusable Metadata Tagging
# ------------------------------------------------------------------------------
variable "application" {
  description = "Application name tag value"
  type        = string
}

variable "owner" {
  description = "Owner email or department tag value"
  type        = string
}

variable "cost_center" {
  description = "Billing Cost Center identifier tag value"
  type        = string
}

variable "compliance" {
  description = "Compliance classification tag value (e.g. HIPAA)"
  type        = string
  default     = "HIPAA"
}

variable "data_classification" {
  description = "Data classification category tag value (e.g. PHI, Confidential)"
  type        = string
  default     = "PHI"
}

variable "backup" {
  description = "Backup strategy tag value (e.g. Daily, MultiRegion)"
  type        = string
  default     = "Daily"
}

variable "alb_ingress_cidr_blocks" {
  description = "Allowed CIDR blocks for ingress to the Application Load Balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_database_networking" {
  description = "Whether to provision the database security group"
  type        = bool
  default     = true
}
