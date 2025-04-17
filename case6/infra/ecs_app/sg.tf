resource "aws_security_group" "alb_sg" {
  name        = "nlb-sg"
  description = "SG for ALB"
  vpc_id      = var.network.vpc_id

  ingress {
    description = "Allow inbound from ALB on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECSタスク用SG
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "SG for ECS tasks"
  vpc_id      = var.network.vpc_id

  # ALBからのHTTP(80)アクセスを許可
  ingress {
    description     = "Allow inbound from ALB on port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}