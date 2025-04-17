# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.vpc.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.vpc.availability_zones[count.index]
}

resource "aws_route_table" "private_route_tables" {
  count  = length(aws_subnet.private_subnets[*].id)
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.private_subnets[*].id)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}