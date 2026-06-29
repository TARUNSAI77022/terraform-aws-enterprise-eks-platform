variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g., dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where ECS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the ECS tasks"
}

variable "container_name" {
  type        = string
  description = "The name of the container"
}

variable "container_port" {
  type        = number
  description = "The port the container listens on"
}

variable "container_image" {
  type        = string
  description = "The ECR image URL to deploy"
}

variable "target_group_arn" {
  type        = string
  description = "The ARN of the ALB Target Group to attach the ECS service to"
}

variable "desired_count" {
  type        = number
  description = "Number of desired tasks to run"
  default     = 2
}

variable "cpu" {
  type        = number
  description = "The amount of CPU used by the task"
  default     = 256
}

variable "memory" {
  type        = number
  description = "The amount of memory used by the task"
  default     = 512
}

variable "aws_region" {
  type        = string
  description = "The AWS region for CloudWatch logs"
}

variable "mongo_uri" {
  type        = string
  description = "MongoDB connection string"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "Secret key for signing JWTs"
  sensitive   = true
}

variable "port" {
  type        = number
  description = "Application port"
  default     = 5000
}

variable "node_env" {
  type        = string
  description = "Node environment (e.g., production, dev)"
}

variable "base_url" {
  type        = string
  description = "Backend Base URL"
}

variable "frontend_url" {
  type        = string
  description = "Frontend Application URL"
}

variable "alb_security_group_id" {
  type        = string
  description = "The ID of the ALB Security Group to allow traffic from"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security groups to associate with the ECS service tasks"
  default     = []
}
