
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs-task"
  retention_in_days = 1
}