output "api_gateway_info" {
  description = "API Gatewayの情報"
  value = {
    command = <<EOT
      curl -X GET ${aws_apigatewayv2_api.main.api_endpoint}/app1/ -H "Authorization: Bearer " 
    EOT
    url     = aws_apigatewayv2_api.main.api_endpoint
  }
}

output "cognito_login_info" {
  description = "Cognitoのログイン情報"
  value = {
    user          = aws_cognito_user.default_user.username
    password      = var.default_user_password
    url           = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/authorize?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&scope=email+openid&redirect_uri=${local.cognito_callback_url}"
    token_command = <<EOT
      curl -X POST "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/token" \
           -H "Content-Type: application/x-www-form-urlencoded" \
           -d "grant_type=authorization_code" \
           -d "client_id=${aws_cognito_user_pool_client.client.id}" \
           -d "redirect_uri=${local.cognito_callback_url}" \
           -d "code="
    EOT
  }
}

output "ecs_ssm_session_info" {
  description = "ECSにSSMセッションを開始するための必要な情報"
  value = {
    cluster_name = aws_ecs_cluster.main.name
  }
}