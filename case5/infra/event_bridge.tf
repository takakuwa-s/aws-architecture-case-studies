locals {
  dynamodb_events = {
    post_event = {
      key          = "post_event"
      event_source = "dynamodb_${aws_dynamodb_table.dynamodb_tables["posts"].name}"
      aws_pipe = {
        name        = "post-to-eventbus_pipe"
        description = "Pipe to send DynamoDB stream events from post table to EventBridge event bus"
        source      = aws_dynamodb_table.dynamodb_tables["posts"].stream_arn
      }
      event_bus = {
        name        = "post-handle-bus"
        description = "Custom event bus for DynamoDB post table events"
      }
    },
    feed_event = {
      key          = "feed_event"
      event_source = "dynamodb_${aws_dynamodb_table.dynamodb_tables["feeds"].name}"
      aws_pipe = {
        name        = "feed-to-eventbus_pipe"
        description = "Pipe to send DynamoDB stream events from feed table to EventBridge event bus"
        source      = aws_dynamodb_table.dynamodb_tables["feeds"].stream_arn
      }
      event_bus = {
        name        = "feed-handle-bus"
        description = "Custom event bus for DynamoDB feed table events"
      }
    }
  }

}


# https://registry.terraform.io/providers/hashicorp/aws/5.83.0/docs/resources/pipes_pipe
resource "aws_pipes_pipe" "aws_pipes" {
  for_each    = local.dynamodb_events
  name        = each.value.aws_pipe.name
  description = each.value.aws_pipe.description
  role_arn    = aws_iam_role.iam_roles[local.iam_roles.pipe_role.key].arn
  source      = each.value.aws_pipe.source
  target      = aws_cloudwatch_event_bus.custom_buses[each.value.key].arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position      = "LATEST"
      batch_size             = 1
      maximum_retry_attempts = 3
    }
  }

  log_configuration {
    include_execution_data = ["ALL"]
    level                  = "INFO"
    cloudwatch_logs_log_destination {
      log_group_arn = aws_cloudwatch_log_group.eventbridge_pipe_log_group.arn
    }
  }

  target_parameters {
    eventbridge_event_bus_parameters {
      source = each.value.event_source
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus
resource "aws_cloudwatch_event_bus" "custom_buses" {
  for_each    = local.dynamodb_events
  name        = each.value.event_bus.name
  description = each.value.event_bus.description
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy
resource "aws_cloudwatch_event_bus_policy" "allow_pipe_to_put_events" {
  for_each       = local.dynamodb_events
  event_bus_name = aws_cloudwatch_event_bus.custom_buses[each.value.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPutEventsFromPipe"
        Effect = "Allow"
        Principal = {
          AWS = aws_pipes_pipe.aws_pipes[each.value.key].role_arn
        }
        Action   = "events:PutEvents"
        Resource = aws_cloudwatch_event_bus.custom_buses[each.value.key].arn
      },
    ]
  })
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
resource "aws_cloudwatch_event_rule" "normal_user_post_rule" {
  name           = "NormalUserPostRule"
  description    = "Rule to trigger SQS for normal user post events"
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  force_destroy  = true
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
  event_pattern = jsonencode({
    source = [local.dynamodb_events["post_event"].event_source]
    detail = {
      eventName = ["INSERT"]
      eventSourceARN = [{
        prefix = aws_dynamodb_table.dynamodb_tables["posts"].arn
      }]
      dynamodb = {
        NewImage = {
          is_celebrity = {
            BOOL = [false]
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "celebrity_user_post_rule" {
  name           = "CelebrityUserPostRule"
  description    = "Rule to trigger SQS for celebrity user post events"
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  force_destroy  = true
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
  event_pattern = jsonencode({
    source = [local.dynamodb_events["post_event"].event_source]
    detail = {
      eventName = ["INSERT"]
      eventSourceARN = [{
        prefix = aws_dynamodb_table.dynamodb_tables["posts"].arn
      }]
      dynamodb = {
        NewImage = {
          is_celebrity = {
            BOOL = [true]
          }
        }
      }
    }
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target
resource "aws_cloudwatch_event_target" "normal_user_post_to_sqs_target" {
  rule           = aws_cloudwatch_event_rule.normal_user_post_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  arn            = aws_sqs_queue.queues["normal"].arn
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
}

resource "aws_cloudwatch_event_target" "normal_user_post_to_log_target" {
  rule           = aws_cloudwatch_event_rule.normal_user_post_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  arn            = aws_cloudwatch_log_group.eventbridge_cusom_bus_log_group.arn
}

resource "aws_cloudwatch_event_target" "celebrity_user_post_to_sqs_target" {
  rule           = aws_cloudwatch_event_rule.celebrity_user_post_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  arn            = aws_sqs_queue.queues["celebrity"].arn
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
}

resource "aws_cloudwatch_event_target" "celebrity_user_post_to_log_target" {
  rule           = aws_cloudwatch_event_rule.celebrity_user_post_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["post_event"].name
  arn            = aws_cloudwatch_log_group.eventbridge_cusom_bus_log_group.arn
}


resource "aws_cloudwatch_event_rule" "notification_rule" {
  name           = "NotificationRule"
  description    = "Rule to trigger SNS and SQS for DynamoDB feed events"
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["feed_event"].name
  force_destroy  = true
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
  event_pattern = jsonencode({
    source = [local.dynamodb_events["feed_event"].event_source]
    detail = {
      eventName = ["INSERT"]
      eventSourceARN = [{
        prefix = aws_dynamodb_table.dynamodb_tables["feeds"].arn
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "feed_to_sns_target" {
  rule           = aws_cloudwatch_event_rule.notification_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["feed_event"].name
  arn            = aws_sns_topic.topic.arn
  role_arn       = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].arn
  input = jsonencode({
    "default" : "create a feed completed"
  })
}

resource "aws_cloudwatch_event_target" "feed_to_log_target" {
  rule           = aws_cloudwatch_event_rule.notification_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_buses["feed_event"].name
  arn            = aws_cloudwatch_log_group.eventbridge_cusom_bus_log_group.arn
}