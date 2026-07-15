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

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_role_arn" {
  description = "The ARN of the IAM role that provides permissions for the EKS cluster control plane"
  type        = string
}

variable "subnet_ids" {
  description = "A list of private subnet IDs to place the EKS cluster and nodes in"
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the EKS cluster"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for EKS secrets envelope encryption"
  type        = string
}

variable "create_oidc_provider" {
  description = "Whether to create the OpenID Connect (OIDC) provider for IAM roles for service accounts"
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

variable "authentication_mode" {
  description = "The authentication mode for the EKS cluster. Can be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "access_entries" {
  description = "Map of access entries to provision for EKS access management"
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

variable "tags" {
  description = "A map of tags to assign to EKS resources"
  type        = map(string)
  default     = {}
}

variable "node_role_arn" {
  description = "The ARN of the IAM role for the EKS node group to map as an EC2_LINUX access entry"
  type        = string
  default     = ""
}

variable "enable_node_access_entry" {
  description = "Whether to create the EKS access entry for the node group. This breaks the plan-time dependency cycle with computed IAM roles."
  type        = bool
  default     = true
}

variable "create_caller_access_entry" {
  description = "Whether Terraform should create the caller EKS Access Entry."
  type        = bool
  default     = true
}



