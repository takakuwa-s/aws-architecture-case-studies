# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.network[0].vpc_id
  peer_vpc_id = module.network[1].vpc_id
  auto_accept = true # 同一アカウント/リージョンの場合は true でOK
}

resource "aws_route" "route_from_vpc0_to_vpc1" {
  count                     = length(module.network[0].route_table_ids)
  route_table_id            = module.network[0].route_table_ids[count.index]
  destination_cidr_block    = local.cidr_blocks[1]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "route_from_vpc1_to_vpc0" {
  count                     = length(module.network[1].route_table_ids)
  route_table_id            = module.network[1].route_table_ids[count.index]
  destination_cidr_block    = local.cidr_blocks[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}