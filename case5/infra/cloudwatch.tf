
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs-task"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "eventbridge_pipe_log_group" {
  name              = "/eventbridge/pipe"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "eventbridge_cusom_bus_log_group" {
  name              = "/eventbridge/cusom-bus"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_resource_policy" "log_event_policy" {
  policy_name = "LogEventsPolicy"
  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "events.amazonaws.com",
            "delivery.logs.amazonaws.com"
          ]
        },
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = ["${aws_cloudwatch_log_group.eventbridge_cusom_bus_log_group.arn}:*"]
      }
    ]
  })
}

# SQSワーカー用のカスタムメトリクスアラーム（メッセージ数に基づく）
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth_high" {
  for_each            = local.queues
  alarm_name          = "${each.key}-sqs-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 100 # キューに100以上のメッセージがある場合
  alarm_description   = "SQS queue depth is too high"
  alarm_actions       = [aws_appautoscaling_policy.sqs_worker_scale_up[each.key].arn]
  dimensions = {
    QueueName = aws_sqs_queue.queues[each.key].name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth_low" {
  for_each            = local.queues
  alarm_name          = "${each.key}-sqs-queue-depth-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 20 # キューに20未満のメッセージがある場合
  alarm_description   = "SQS queue depth is low"
  alarm_actions       = [aws_appautoscaling_policy.sqs_worker_scale_up[each.key].arn]
  dimensions = {
    QueueName = aws_sqs_queue.queues[each.key].name
  }
}