locals {
  iam_roles = {
    eks_cluster_role = {
      name    = "eks-cluster-role"
      service = "eks.amazonaws.com"
    },
    eks_node_role = {
      name    = "eks-node-role"
      service = "ec2.amazonaws.com"
    },
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

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.iam_roles["eks_cluster_role"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "node_worker_node_policy" {
  role       = aws_iam_role.iam_roles["eks_node_role"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.iam_roles["eks_node_role"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_readonly" {
  role       = aws_iam_role.iam_roles["eks_node_role"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "cloudwatch_logs_for_fluentbit" {
  name = "fluentbit-cloudwatch-logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_fluentbit_policy" {
  role       = aws_iam_role.iam_roles["eks_node_role"].name
  policy_arn = aws_iam_policy.cloudwatch_logs_for_fluentbit.arn
}
