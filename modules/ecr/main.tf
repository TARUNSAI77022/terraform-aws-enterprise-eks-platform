# Purpose: This module provisions an Amazon ECR (Elastic Container Registry) repository.
# ECR will securely store the Docker container images for our application.
# Later, ECS (Elastic Container Service) tasks will pull these images from ECR to run the application containers.
# During Blue/Green deployments, updated images will be pushed here, and CodeDeploy will orchestrate 
# the shift of traffic to new ECS tasks running the latest image versions.

resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr-repository-this"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
