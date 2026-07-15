variable "chart_version" {
  description = "The version of the Helm chart to install for Metrics Server"
  type        = string
  default     = "3.12.1"
}

variable "tags" {
  description = "A map of tags to assign to resources (where applicable)"
  type        = map(string)
  default     = {}
}

variable "enable" {
  description = "Whether to deploy the Metrics Server Helm release"
  type        = bool
  default     = true
}

