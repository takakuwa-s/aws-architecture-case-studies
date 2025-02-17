resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = {
    Name = "my-ecs-listener"
  }
}

locals {
  service_map = {
    for idx, s in var.services :
    s.name => {
      path = s.path
      idx  = idx
    }
  }
}

resource "aws_lb_listener_rule" "rules" {
  for_each = local.service_map

  listener_arn = aws_lb_listener.ecs_listener.arn
  priority     = 10 + each.value.idx

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tgs[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }

  tags = {
    Name = "rule-${each.key}"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "ecs_tgs" {
  for_each = {
    for s in var.services : s.name => s
  }

  name        = "tg-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
  }

  tags = {
    Name = "tg-${each.key}"
  }
}
