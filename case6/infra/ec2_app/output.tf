output "alb_dns_name" {
  value       = aws_lb.ec2_alb.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "api_gateway_url" {
  description = "API GatewayのURL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}