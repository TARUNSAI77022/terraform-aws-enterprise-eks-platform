output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_target_group_blue_arn" {
  description = "The ARN of the Blue ALB Target Group"
  value       = aws_lb_target_group.blue.arn
}

output "alb_target_group_green_arn" {
  description = "The ARN of the Green ALB Target Group"
  value       = aws_lb_target_group.green.arn
}

output "alb_target_group_blue_name" {
  description = "The Name of the Blue ALB Target Group"
  value       = aws_lb_target_group.blue.name
}

output "alb_target_group_green_name" {
  description = "The Name of the Green ALB Target Group"
  value       = aws_lb_target_group.green.name
}

output "alb_listener_arn" {
  description = "The ARN of the ALB Listener"
  value       = aws_lb_listener.http.arn
}

output "alb_security_group_id" {
  description = "The ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}
