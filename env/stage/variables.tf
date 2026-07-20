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
  default     = "stage"

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
# Phase Ingress Configuration
# ------------------------------------------------------------------------------
variable "alb_ingress_cidr_blocks" {
  description = "Allowed CIDR blocks for ingress to the Application Load Balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# Phase 2: EKS Platform Configuration Variables
# ------------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "The target Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = "v1.11.1-eksbuild.9"
}

variable "kube_proxy_version" {
  description = "kube-proxy addon version"
  type        = string
  default     = "v1.31.0-eksbuild.5"
}

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = "v1.18.1-eksbuild.3"
}

variable "ebs_csi_version" {
  description = "EBS CSI Driver addon version"
  type        = string
  default     = "v1.31.0-eksbuild.1"
}

variable "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.8.1"
}

variable "cluster_autoscaler_version" {
  description = "Cluster Autoscaler Helm chart version"
  type        = string
  default     = "9.37.0"
}

variable "metrics_server_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.12.1"
}

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider for IRSA"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "The ARN of the existing EKS OIDC Provider if create_oidc_provider is false"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "The URL of the existing EKS OIDC Provider if create_oidc_provider is false"
  type        = string
  default     = ""
}

variable "endpoint_private_access" {
  description = "Enable EKS private API server endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable EKS public API server endpoint access"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Allowed CIDR blocks for EKS public endpoint access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "authentication_mode" {
  description = "EKS authentication mode"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "access_entries" {
  description = "Map of access entries and role associations to configure on EKS"
  type = map(object({
    principal_arn = string
    type          = optional(string, "STANDARD")
    user_name     = optional(string)
    policy_arn    = optional(string)
    access_scope = optional(object({
      type       = string
      namespaces = optional(list(string))
    }), { type = "cluster" })
  }))
  default = {}
}

variable "node_groups" {
  description = "A map of node groups to provision"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
  }))
  default = {
    system = {
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 50
    }
    applications = {
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      disk_size      = 50
    }
  }
}

# IAM Policies configuration variables
variable "create_lb_controller_policy" {
  description = "Whether to create the custom IAM policy for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "create_cluster_autoscaler_policy" {
  description = "Whether to create the custom IAM policy for EKS Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "use_existing_lb_controller_policy" {
  description = "Whether to reuse an existing IAM policy for AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "existing_lb_controller_policy_arn" {
  description = "ARN of the existing IAM policy for AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "use_existing_cluster_autoscaler_policy" {
  description = "Whether to reuse an existing IAM policy for EKS Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "existing_cluster_autoscaler_policy_arn" {
  description = "ARN of the existing IAM policy for EKS Cluster Autoscaler"
  type        = string
  default     = ""
}

# KMS Keys configuration variables
variable "create_eks_kms" {
  description = "Whether to create the KMS key for EKS"
  type        = bool
  default     = true
}

variable "create_cloudwatch_kms" {
  description = "Whether to create the KMS key for CloudWatch"
  type        = bool
  default     = true
}

variable "create_ecr_kms" {
  description = "Whether to create the KMS key for ECR"
  type        = bool
  default     = true
}

variable "use_existing_eks_kms" {
  description = "Whether to reuse an existing KMS key for EKS"
  type        = bool
  default     = false
}

variable "existing_eks_kms_alias" {
  description = "Alias of the existing KMS key for EKS (e.g. alias/custom-eks-key)"
  type        = string
  default     = ""
}

variable "use_existing_cloudwatch_kms" {
  description = "Whether to reuse an existing KMS key for CloudWatch"
  type        = bool
  default     = false
}

variable "existing_cloudwatch_kms_alias" {
  description = "Alias of the existing KMS key for CloudWatch"
  type        = string
  default     = ""
}

variable "use_existing_ecr_kms" {
  description = "Whether to reuse an existing KMS key for ECR"
  type        = bool
  default     = false
}

variable "existing_ecr_kms_alias" {
  description = "Alias of the existing KMS key for ECR"
  type        = string
  default     = ""
}

