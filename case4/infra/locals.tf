locals {
  cognito_callback_url = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}