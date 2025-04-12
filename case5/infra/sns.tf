# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
resource "aws_sns_topic" "topic" {
  name         = "notification-handle-topic"
  display_name = "Notification Handle Topic"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  count     = length(var.target_emails)
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.target_emails[count.index]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy
resource "aws_sns_topic_policy" "topic_policy" {
  arn = aws_sns_topic.topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.topic.arn
        Condition : {
          ArnEquals : {
            "aws:SourceArn" = aws_cloudwatch_event_bus.custom_buses["feed_event"].arn
          }
        }

      }
    ]
  })
}