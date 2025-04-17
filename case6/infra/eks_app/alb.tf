# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "eks_alb" {
  name               = "eks-slb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_ids.alb_sg_id, ]
  subnets            = var.network.private_subnet_ids
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "eks_listener" {
  load_balancer_arn = aws_lb.eks_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_tg.arn #転送先のターゲットグループを指定
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "eks_tg" {
  name     = "eks-tg"
  port     = 80 #ALBから通信先に接続する際のポート番号
  protocol = "HTTP"
  vpc_id   = var.network.vpc_id
  health_check {
    path                = "/" #ヘルスチェックのパス
    interval            = 30  #ヘルスチェックの実行間隔（秒）
    timeout             = 5   #ヘルスチェックのタイムアウト時間（秒）
    healthy_threshold   = 2   #2回連続で成功すれば正常と判断
    unhealthy_threshold = 2   #2回連続で失敗すれば異常と判断
  }
}
