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

output "dynamodb_table_name" {
  description = "Lead storage DynamoDB table name."
  value       = aws_dynamodb_table.leads.name
}

output "custom_domain_url" {
  description = "Custom domain URL when enabled."
  value       = local.custom_domain_enabled ? "https://${local.site_domain}" : null
}

output "name_prefix" {
  description = "Normalized prefix for resources."
  value       = local.name_prefix
}
