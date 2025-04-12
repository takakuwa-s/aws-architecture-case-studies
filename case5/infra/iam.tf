locals {
  iam_roles = {
    ecs_task_role = {
      key     = "ecs_task_role"
      name    = "ecs-task-role"
      service = "ecs-tasks.amazonaws.com"
    },
    ecs_execution_role = {
      key     = "ecs_execution_role"
      name    = "ecs-execution-role"
      service = "ecs-tasks.amazonaws.com"
    },
    eventbridge_role = {
      key     = "eventbridge_role"
      name    = "eventbridge-role"
      service = "events.amazonaws.com"
    },
    pipe_role = {
      key     = "pipe_role"
      name    = "pipe-role"
      service = "pipes.amazonaws.com"
    }
  }
}

resource "aws_iam_role" "iam_roles" {
  for_each = local.iam_roles
  name     = each.value.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = [each.value.service]
        }
      }
    ]
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecs-task-policy"
  role = aws_iam_role.iam_roles[local.iam_roles.ecs_task_role.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:UpdateItem", "dynamodb:Scan"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["elasticache:DescribeCacheClusters"]
        Resource = "*"
      },
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution_policy" {
  name = "ecs-execution-policy"
  role = aws_iam_role.iam_roles[local.iam_roles.ecs_execution_role.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:GetAuthorizationToken"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipe_policy" {
  name = "dynamodb-pipe-policy"
  role = aws_iam_role.iam_roles[local.iam_roles.pipe_role.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "events_policy" {
  name = "events-to-sns-policy"
  role = aws_iam_role.iam_roles[local.iam_roles.eventbridge_role.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "logs_policy" {
  name        = "logs_policy"
  description = "Permissions for ECS execution (ECR, CloudWatch Logs)"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each   = local.iam_roles
  role       = aws_iam_role.iam_roles[each.key].name
  policy_arn = aws_iam_policy.logs_policy.arn
}