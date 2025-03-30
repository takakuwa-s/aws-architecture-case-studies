# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool
resource "aws_cognito_user_pool" "pool" {
  name                     = "webapp-user-pool"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client
resource "aws_cognito_user_pool_client" "client" {
  name                                 = "my-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = false
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  callback_urls                = [local.cognito_callback_url]
  allowed_oauth_scopes         = ["email", "openid"]
  allowed_oauth_flows          = ["code"]
  supported_identity_providers = ["COGNITO"]
}


# Cognito Domain
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "api-auth-domain-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# ランダムサフィックス（ドメイン名の一意性確保用）
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user
resource "aws_cognito_user" "default_user" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "testuser"
  attributes = {
    email          = "testuser@example.com"
    email_verified = "true"
  }
  force_alias_creation = false
  message_action       = "SUPPRESS"                # 初回のメール通知を無効化
  password             = var.default_user_password # 初回パスワード（要件を満たす必要あり）
}