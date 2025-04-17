resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.network.private_subnet_ids

  security_groups = [
    var.sg_ids.alb_sg_id,
  ]
}

# HTTP → HTTPS リダイレクトリスナー
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

}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
resource "aws_lb_listener_rule" "rules" {
  for_each = {
    for k, v in var.services : k => v
    if v.alb_state
  }

  listener_arn = aws_lb_listener.ecs_listener.arn
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
    for k, v in var.services : k => v
    if v.alb_state
  }

  name        = "tg-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.network.vpc_id

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