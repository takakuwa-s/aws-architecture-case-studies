resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "SG for ALB"
  vpc_id      = aws_vpc.main.id

  # ALBに対するHTTP(80)アクセスを全IPから許可（実運用では制限要検討）
  ingress {
    description = "Allow HTTP inbound"
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

  tags = {
    Name = "alb-sg"
  }
}

# ECSタスク用SG
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "SG for ECS tasks"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Name = "ecs-tasks-sg"
  }
}
