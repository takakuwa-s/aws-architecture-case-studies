# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "latest_amazon_linux" {
  most_recent = true       # 最新の AMI を取得
  owners      = ["amazon"] # AWS公式AMIのみ検索
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"] # arm64 向けの AMI
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
resource "aws_launch_template" "web" {
  name          = "web-template"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t4g.nano"
  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_instance_profile.arn
  }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "web-server" }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello from EC2 app" | sudo tee /var/www/html/index.html
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
  EOF
  )
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "web" {
  vpc_zone_identifier = var.network.private_subnet_ids
  desired_capacity    = 1 #通常時のEC2インスタンス数
  min_size            = 1 #最低維持するEC2インスタンス数
  max_size            = 3 #最大維持するEC2インスタンス数

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1  #スケールアウト時の追加するEC2インスタンス数
  cooldown               = 60 #スケールアウト後の次のスケールアウトまでの待ち時間
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity" #インスタンス数を直接変更
  scaling_adjustment     = -1                 #スケールイン時の削除するEC2インスタンス数
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
