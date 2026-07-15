locals {
  name_prefix = var.project_name

  # Ensure Target Group names include project name, environment, and service color/name.
  # AWS enforces a maximum length of 32 characters for target group names.
  # We restrict project_prefix length dynamically to keep the final names within 32 characters.
  max_proj_len  = 32 - 10 - length(var.environment) # "-green-tg" is 9 chars + 1 hyphen = 10
  proj_prefix   = substr(var.project_name, 0, local.max_proj_len)

  tg_blue_name  = "${local.proj_prefix}-${var.environment}-blue-tg"
  tg_green_name = "${local.proj_prefix}-${var.environment}-green-tg"
}

# ------------------------------------------------------------------------------
# ALB Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP inbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-security-group-alb"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags = {
    Name        = "${var.project_name}-${var.environment}-lb-main"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# Target Groups (Blue / Green)
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "blue" {
  name        = local.tg_blue_name
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-lb-target-group-blue"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "green" {
  name        = local.tg_green_name
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-lb-target-group-green"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# Listener
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  # CodeDeploy will switch the target group between blue and green
  lifecycle {
    ignore_changes = [default_action]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-lb-listener-http"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

