# CloudWatch Log Group for ECS Tasks
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudwatch-log-group-ecs-log-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Security Group
# Controls inbound and outbound traffic for the ECS tasks
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Inbound traffic on container port
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow inbound traffic on container port from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-security-group-ecs-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cluster-main"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Task Definition (Fargate)
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  depends_on = [
    aws_iam_role.ecs_task_role,
    aws_iam_role_policy.ecs_exec_policy
  ]

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    healthCheck = {
      command = [
        "CMD-SHELL",
        "curl -f http://localhost:5000/api/health || exit 1"
      ]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
    environment = [
      { name = "FORCE_TASK_DEF_REVISION", value = "2" }
    ]
    secrets = [
      { name = "PORT", valueFrom = aws_ssm_parameter.port.arn },
      { name = "MONGO_URI", valueFrom = aws_ssm_parameter.mongo_uri.arn },
      { name = "JWT_SECRET", valueFrom = aws_ssm_parameter.jwt_secret.arn },
      { name = "NODE_ENV", valueFrom = aws_ssm_parameter.node_env.arn },
      { name = "BASE_URL", valueFrom = aws_ssm_parameter.base_url.arn },
      { name = "FRONTEND_URL", valueFrom = aws_ssm_parameter.frontend_url.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-definition-main"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                   = "${var.project_name}-${var.environment}-bg-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.main.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Ignore task definition changes to allow CI/CD deployments (like CodeDeploy) to update the service
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
      desired_count,
      enable_execute_command
    ]
  }

  depends_on = [
    aws_iam_role.ecs_task_role,
    aws_iam_role_policy.ecs_exec_policy,
    aws_ecs_task_definition.main
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-service-main"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
