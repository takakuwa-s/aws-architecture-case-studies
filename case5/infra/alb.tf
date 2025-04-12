resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.app-private[*].id

  security_groups = [
    aws_security_group.alb_sg.id
  ]
}

# HTTP → HTTPS リダイレクトリスナー
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
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

}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
resource "aws_lb_listener_rule" "rules" {
  for_each = {
    for k, v in local.services : k => v
    if v.alb_state
  }

  listener_arn = aws_lb_listener.listener.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tgs[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }
}

# ALB 用のターゲットグループ
resource "aws_lb_target_group" "ecs_tgs" {
  for_each = {
    for k, v in local.services : k => v
    if v.alb_state
  }

  name        = "tg-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
  }
}