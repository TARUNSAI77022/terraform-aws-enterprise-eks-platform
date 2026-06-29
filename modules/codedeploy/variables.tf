variable "project_name" { type = string }
variable "environment" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "alb_listener_arn" { type = string }
variable "blue_target_group_name" { type = string }
variable "green_target_group_name" { type = string }
