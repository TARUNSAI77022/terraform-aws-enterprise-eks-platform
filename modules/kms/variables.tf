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
