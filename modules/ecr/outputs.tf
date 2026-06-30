output "repository_urls" {
  description = "A map of repository names to their URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_names" {
  description = "A map of repository names to their actual AWS names"
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "repository_arns" {
  description = "A map of repository names to their ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}
