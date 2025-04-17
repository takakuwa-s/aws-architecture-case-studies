output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = aws_subnet.private_subnets[*].id
  description = "Private Subnet IDs"
}

output "route_table_ids" {
  value       = aws_route_table.private_route_tables[*].id
  description = "Route Table IDs"
}