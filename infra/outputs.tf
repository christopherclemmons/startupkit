output "api_url" {
  description = "HTTP API invoke URL."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "amplify_app_id" {
  description = "Amplify app ID when Amplify is enabled."
  value       = local.amplify_app_enabled ? aws_amplify_app.frontend[0].id : null
}

output "amplify_default_domain" {
  description = "Amplify default domain when Amplify is enabled."
  value       = local.amplify_app_enabled ? aws_amplify_app.frontend[0].default_domain : null
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID for the site admin."
  value       = aws_cognito_user_pool.admin.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito app client ID for the site admin login."
  value       = aws_cognito_user_pool_client.admin.id
}

output "cognito_domain" {
  description = "Managed Cognito domain for admin sign-in."
  value       = local.cognito_domain_host
}

output "dynamodb_table_name" {
  description = "Lead and content storage DynamoDB table name."
  value       = aws_dynamodb_table.site_data.name
}

output "custom_domain_url" {
  description = "Custom domain URL when enabled."
  value       = nonsensitive(local.custom_domain_enabled ? "https://${local.site_domain}" : null)
}

output "name_prefix" {
  description = "Normalized prefix for resources."
  value       = local.name_prefix
}
