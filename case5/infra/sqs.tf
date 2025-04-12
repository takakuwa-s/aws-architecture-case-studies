locals {
  queues = {
    normal = {
      key  = "process_user_queue"
      name = "ProcessUserQueue"
    },
    celebrity = {
      key  = "process_celebrity_queue"
      name = "ProcessCelebrityQueue"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue
resource "aws_sqs_queue" "queues" {
  for_each                   = local.queues
  name                       = each.value.name
  message_retention_seconds  = 60 * 60 * 24
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 60
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy
resource "aws_sqs_queue_policy" "queue_policy" {
  for_each  = local.queues
  queue_url = aws_sqs_queue.queues[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.queues[each.key].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_bus.custom_buses["post_event"].arn
          }
        }
      }
    ]
  })
}