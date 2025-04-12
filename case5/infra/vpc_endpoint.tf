
locals {
  gateway_service_names = [
    "com.amazonaws.${data.aws_region.current.name}.s3",
    "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  ]
  interface_service_names = [
    "com.amazonaws.${data.aws_region.current.name}.sqs",
    "com.amazonaws.${data.aws_region.current.name}.ecr.api",
    "com.amazonaws.${data.aws_region.current.name}.ecr.dkr",
    "com.amazonaws.${data.aws_region.current.name}.logs",
    "com.amazonaws.${data.aws_region.current.name}.ssm",
    "com.amazonaws.${data.aws_region.current.name}.ssmmessages",
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint.html
resource "aws_vpc_endpoint" "vpc_gateway_endpoints" {
  for_each          = toset(local.gateway_service_names)
  vpc_id            = aws_vpc.main.id
  service_name      = each.key
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.app-private[*].id
}

resource "aws_vpc_endpoint" "vpc_interface_endpoints" {
  for_each            = toset(local.interface_service_names)
  vpc_id              = aws_vpc.main.id
  service_name        = each.key
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.app-private[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id,
  ]
}