# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint.html
resource "aws_vpc_endpoint" "vpc_gateway_endpoints" {
  for_each          = toset(var.gateway_service_names)
  vpc_id            = aws_vpc.main.id
  service_name      = each.key
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private_route_tables[*].id
}

resource "aws_vpc_endpoint" "vpc_interface_endpoints" {
  for_each            = toset(var.interface_service_names)
  vpc_id              = aws_vpc.main.id
  service_name        = each.key
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id,
  ]
}