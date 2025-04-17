# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "main" {
  name = "webapp-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "app_services" {
  for_each               = var.services
  name                   = "${each.key}-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.tasks[each.key].arn
  launch_type            = "FARGATE"
  desired_count          = each.value.desired_count
  enable_execute_command = true

  network_configuration {
    subnets          = var.network.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.value.alb_state ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.ecs_tgs[each.key].arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  deployment_controller {
    type = "ECS"
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.listener]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "tasks" {
  for_each = var.services

  family                   = "${each.key}-family"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.iam_roles["ecs_execution_role"].arn
  task_role_arn            = aws_iam_role.iam_roles["ecs_task_role"].arn


  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${var.image_url}:latest"
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
        }
      ]
      command = each.value.command

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = each.value.name
        }
      }
      environment : [
        {
          name : "ENV_CONTEXT",
          value : "ECR_${each.value.name}"
        },
      ]
    }
  ])
}