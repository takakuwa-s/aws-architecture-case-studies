# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.common["ec2"].vpc_id
  peer_vpc_id = module.common["ecs"].vpc_id
  auto_accept = true # 同一アカウント/リージョンの場合は true でOK
}

resource "aws_route" "route_from_ec2_to_ecs" {
  count                     = length(module.common["ec2"].route_table_ids)
  route_table_id            = module.common["ecs"].route_table_ids[count.index]
  destination_cidr_block    = local.app_commons["ecs"].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "route_from_ecs_to_ec2" {
  count                     = length(module.common["ecs"].route_table_ids)
  route_table_id            = module.common["ecs"].route_table_ids[count.index]
  destination_cidr_block    = local.app_commons["ec2"].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options
resource "aws_vpc_peering_connection_options" "peer_dns" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}