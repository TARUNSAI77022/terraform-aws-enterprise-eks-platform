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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[1-2][0-9]$", var.vpc_cidr))
    error_message = "The vpc_cidr must be a valid IPv4 CIDR block with block size /10 to /29."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

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
  description = "CIDR blocks for private application subnets"
  type        = list(string)

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
  description = "CIDR blocks for private database subnets"
  type        = list(string)

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
# Networking Strategies
# ------------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways for private outbound internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Set to true to deploy a single NAT Gateway shared across subnets (costs-optimized). Set to false to deploy one NAT Gateway per availability zone (highly available)."
  type        = bool
  default     = false
}

variable "enable_database_networking" {
  description = "Whether to provision database subnets and related networking resources"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Logging Requirements
# ------------------------------------------------------------------------------
variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs sent to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch Logs"
  type        = number
  default     = 365

  validation {
    condition     = contains([30, 90, 365], var.flow_logs_retention_days)
    error_message = "VPC Flow Logs retention must be one of: 30 (Dev), 90 (Stage), or 365 (Prod)."
  }
}

# ------------------------------------------------------------------------------
# Integrations and Future EKS Tags
# ------------------------------------------------------------------------------
variable "eks_cluster_name" {
  description = "Name of the future Amazon EKS Cluster. If provided, subnets will receive standard kubernetes.io tags."
  type        = string
  default     = ""
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
