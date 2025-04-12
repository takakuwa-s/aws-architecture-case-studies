output "api_gateway_info" {
  description = "API Gatewayの情報"
  value = {
    command = <<EOT
      curl -X POST -H "Content-Type: application/json" \
        ${aws_apigatewayv2_api.main.api_endpoint}/api/post/ \
        -d '{"user_id":"1", "message":"hello", "is_celebrity": true}'
    EOT
    feeds   = "curl -X GET ${aws_apigatewayv2_api.main.api_endpoint}/api/feeds/1"
    users   = "curl -X GET ${aws_apigatewayv2_api.main.api_endpoint}/api/users/1"
    health  = "curl -X GET ${aws_apigatewayv2_api.main.api_endpoint}/api/"
    url     = aws_apigatewayv2_api.main.api_endpoint
  }
}


output "ecs_ssm_session_info" {
  description = "ECSにSSMセッションを開始するための必要な情報"
  value       = <<EOT
    aws ecs execute-command \
      --cluster ${aws_ecs_cluster.main.name} \
      --command "/bin/sh" \
      --interactive \
      --task 
    EOT
}

output "ecs_commands" {
  description = "ECSのコマンド集"
  value = {
    update_task_images = <<EOT
      ./deploy.sh \
        ${aws_ecr_repository.server.repository_url} \
        ${aws_ecs_cluster.main.name}
    EOT
  }
}