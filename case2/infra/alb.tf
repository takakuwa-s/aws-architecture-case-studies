# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "app-lb" }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80 #ALBから通信先に接続する際のポート番号
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/" #ヘルスチェックのパス
    interval            = 30  #ヘルスチェックの実行間隔（秒）
    timeout             = 5   #ヘルスチェックのタイムアウト時間（秒）
    healthy_threshold   = 2   #2回連続で成功すれば正常と判断
    unhealthy_threshold = 2   #2回連続で失敗すれば異常と判断
  }

  tags = { Name = "app-tg" }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn #転送先のターゲットグループを指定
  }
}
