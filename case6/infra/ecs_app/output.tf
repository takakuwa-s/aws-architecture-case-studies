output "api_gateway_url" {
  description = "API GatewayのURL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "ecs_cluster_name" {
  description = "ECSのクラスター名"
  value       = aws_ecs_cluster.main.name
}