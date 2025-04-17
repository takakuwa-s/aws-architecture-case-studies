# API用サービスのAuto Scalingターゲット
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target
resource "aws_appautoscaling_target" "ecs_services" {
  for_each           = var.services
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app_services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scalingポリシー（CPU使用率に基づく）
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy
resource "aws_appautoscaling_policy" "api_service_cpu" {
  for_each           = var.services
  name               = "${each.key}-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0 # 70% CPU使用率でスケール
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# API用サービスのAuto Scalingポリシー（ALBリクエスト数に基づく）
resource "aws_appautoscaling_policy" "api_service_alb" {
  for_each = {
    for k, v in var.services : k => v
    if v.alb_state
  }
  name               = "${each.key}-alb-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.ecs_alb.arn_suffix}/${aws_lb_target_group.ecs_tgs[each.key].arn_suffix}"
    }
    target_value       = 1000.0 # ターゲットごとに1000リクエストを処理できる
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}