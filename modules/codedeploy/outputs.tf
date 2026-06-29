output "application_name" {
  value = aws_codedeploy_app.ecs_app.name
}

output "deployment_group_name" {
  value = aws_codedeploy_deployment_group.ecs_dg.deployment_group_name
}
