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
    arn = aws_iam_instance_profile.instance_profile.arn
  }
  vpc_security_group_ids = [var.sg_ids.app_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "web-server" }
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd awslogs

# index.html の作成
echo "Hello from EC2 app" > /var/www/html/index.html

# httpd の起動
systemctl start httpd
systemctl enable httpd

# httpd.conf の修正（アクセス制御を許可）
sed -i '/<Directory "\\/var\\/www\\/html">/,/<\\/Directory>/ s/Require .*/Require all granted/' /etc/httpd/conf/httpd.conf
systemctl restart httpd

# CloudWatch Logs 設定ファイルの修正
cat <<EOT > /etc/awslogs/awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/httpd/access_log]
file = /var/log/httpd/access_log
log_group_name = ${var.cloud_Watch_log_group_name}
log_stream_name = {instance_id}/access_log
initial_position = start_of_file
datetime_format = [%d/%b/%Y:%H:%M:%S %z]

[/var/log/httpd/error_log]
file = /var/log/httpd/error_log
log_group_name = ${var.cloud_Watch_log_group_name}
log_stream_name = {instance_id}/error_log
initial_position = start_of_file
EOT

# CloudWatch Agent の AWS CLI 設定ファイル
cat <<EOT > /etc/awslogs/awscli.conf
[plugins]
cwlogs = cwlogs

[default]
region = ${var.aws_region}
EOT

# CloudWatch Agent 起動
systemctl enable awslogsd
systemctl start awslogsd
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

  target_group_arns = [aws_lb_target_group.ec2_tg.arn]
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
