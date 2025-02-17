resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "app_services" {
  for_each = {
    for s in var.services : s.name => s
  }

  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tasks[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tgs[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

  depends_on = [
    aws_lb_listener.ecs_listener
  ]

  tags = {
    Name = "service-${each.key}"
  }
}


resource "aws_ecs_task_definition" "tasks" {
  for_each = {
    for s in var.services : s.name => s
  }

  family                   = "${each.key}-family" #論理的なグルーピング
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
        }
      ]
    }
  ])
}
