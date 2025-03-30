resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/ecs-task"
  retention_in_days = 1
}