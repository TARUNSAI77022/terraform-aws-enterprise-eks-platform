variable "cluster_name" {
  description = "The name of the EKS cluster for which to create the log group"
  type        = string
}

variable "retention_days" {
  description = "Specifies the number of days you want to retain log events in the log group"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting log data"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the log group"
  type        = map(string)
  default     = {}
}
