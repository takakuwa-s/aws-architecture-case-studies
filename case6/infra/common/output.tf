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

output "cloud_Watch_log_group_name" {
  value       = aws_cloudwatch_log_group.log_group.name
  description = "CloudWatch Log Group Name"
}

output "sg_ids" {
  value = {
    "alb_sg_id" = aws_security_group.alb_sg.id
    "app_sg_id" = aws_security_group.app_sg.id
  }
  description = "Security Group IDs"
}