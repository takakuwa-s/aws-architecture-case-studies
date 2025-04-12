# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "app-private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(["ap-northeast-1a", "ap-northeast-1c"], count.index)
}

resource "aws_subnet" "redis-private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = element(["ap-northeast-1a", "ap-northeast-1c"], count.index)
}

resource "aws_route_table" "app-private" {
  count  = length(aws_subnet.app-private[*].id)
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "app-private" {
  count          = length(aws_subnet.app-private[*].id)
  subnet_id      = aws_subnet.app-private[count.index].id
  route_table_id = aws_route_table.app-private[count.index].id
}