resource "aws_apigatewayv2_api" "main" {
  name          = "serverside-api"
  protocol_type = "HTTP"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_vpc_link
resource "aws_apigatewayv2_vpc_link" "alb_link" {
  name               = "alb-vpc-link"
  security_group_ids = [aws_security_group.alb_sg.id]
  subnet_ids         = var.network.private_subnet_ids
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.listener.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.alb_link.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route
resource "aws_apigatewayv2_route" "app1_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"

  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}
