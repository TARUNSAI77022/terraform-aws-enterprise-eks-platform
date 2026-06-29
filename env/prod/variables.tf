variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-foundation"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name)) && length(var.project_name) > 0
    error_message = "The project name must be a non-empty alphanumeric string (hyphens are allowed)."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "The environment must be one of: dev, stage, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[1-2][0-9]$", var.vpc_cidr))
    error_message = "The vpc_cidr must be a valid IPv4 CIDR block with block size /10 to /29."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Multi-AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required to implement a Multi-AZ architecture."
  }

  validation {
    condition     = length(var.public_subnet_cidrs) == length(distinct(var.public_subnet_cidrs))
    error_message = "Duplicate CIDR blocks are not allowed in public subnets."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Each entry in public_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (Multi-AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private application subnets are required to implement a Multi-AZ architecture."
  }

  validation {
    condition     = length(var.private_subnet_cidrs) == length(distinct(var.private_subnet_cidrs))
    error_message = "Duplicate CIDR blocks are not allowed in private application subnets."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Each entry in private_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (Multi-AZ)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least 2 private database subnets are required to implement a Multi-AZ architecture."
  }

  validation {
    condition     = length(var.database_subnet_cidrs) == length(distinct(var.database_subnet_cidrs))
    error_message = "Duplicate CIDR blocks are not allowed in private database subnets."
  }

  validation {
    condition     = alltrue([for cidr in var.database_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Each entry in database_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

# ------------------------------------------------------------------------------
# Tagging Variables
# ------------------------------------------------------------------------------
variable "application" {
  description = "Application name tag value"
  type        = string
  default     = "Infrastructure"
}

variable "owner" {
  description = "Owner department or email tag value"
  type        = string
  default     = "Platform-Team"
}

variable "cost_center" {
  description = "Billing Cost Center identifier tag value"
  type        = string
  default     = "Engineering"
}

variable "compliance" {
  description = "Compliance classification tag value"
  type        = string
  default     = "HIPAA"
}

variable "data_classification" {
  description = "Data classification category tag value"
  type        = string
  default     = "Confidential"
}

variable "backup" {
  description = "Backup strategy tag value"
  type        = string
  default     = "Enabled"
}

# ------------------------------------------------------------------------------
# App Module Parameters
# ------------------------------------------------------------------------------
variable "mongo_uri" {
  description = "MongoDB Connection URI"
  type        = string
  sensitive   = true
  default     = "mongodb://dummy-placeholder"
}

variable "jwt_secret" {
  description = "JWT Secret Key"
  type        = string
  sensitive   = true
  default     = "dummy-secret"
}

variable "port" {
  description = "Application port"
  type        = number
  default     = 5000
}

variable "node_env" {
  description = "Node environment"
  type        = string
  default     = "production"
}

variable "base_url" {
  description = "Backend Base URL"
  type        = string
  default     = "https://dummy-api.example.com"
}

variable "frontend_url" {
  description = "Frontend Application URL"
  type        = string
  default     = "https://dummy-frontend.example.com"
}

# ------------------------------------------------------------------------------
# Phase Enablement Flags (Feature Flags)
# ------------------------------------------------------------------------------
variable "enable_vpc" {
  description = "Enable Cloud Foundation VPC and networking resources"
  type        = bool
  default     = true
}

variable "enable_ecr" {
  description = "Enable Phase 2 Container Registry (ECR)"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable Phase 3 Container Platform (ECS)"
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Enable Phase 4 Application Load Balancer (ALB)"
  type        = bool
  default     = false
}

variable "enable_codedeploy" {
  description = "Enable Phase 5 Deployment Platform (CodeDeploy)"
  type        = bool
  default     = false
}

variable "alb_ingress_cidr_blocks" {
  description = "Allowed CIDR blocks for ingress to the Application Load Balancer. In production, restrict this to Corporate VPN or trusted public CIDRs."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
