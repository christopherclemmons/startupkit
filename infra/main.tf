terraform {
  required_version = ">= 1.5.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  sanitized_app_name = replace(replace(replace(lower(var.app_name), " ", "-"), "_", "-"), ".", "-")
  sanitized_env_name = replace(replace(replace(lower(var.environment), " ", "-"), "_", "-"), ".", "-")
  name_prefix        = trimsuffix("${local.sanitized_app_name}-${local.sanitized_env_name}", "-")
  api_name           = "${local.name_prefix}-site-api"
  table_name         = "${local.name_prefix}-site-data"
  site_domain        = var.enable_custom_domain && var.root_domain != "" ? "${var.subdomain}.${var.root_domain}" : ""
  source_site        = local.site_domain != "" ? local.site_domain : var.subdomain

  common_tags = merge(
    {
      AppName      = var.app_name
      Environment  = var.environment
      BusinessName = var.business_name
      ManagedBy    = "terraform"
    },
    var.tags,
  )

  amplify_app_enabled        = var.enable_amplify_app
  amplify_repository_url     = trimspace(var.amplify_repository_url)
  amplify_access_token       = trimspace(var.amplify_access_token) == "replace-with-amplify-access-token-or-leave-empty" ? "" : trimspace(var.amplify_access_token)
  amplify_repository_enabled = local.amplify_app_enabled && local.amplify_repository_url != "" && local.amplify_access_token != ""
  custom_domain_enabled      = local.amplify_repository_enabled && var.enable_custom_domain && var.root_domain != "" && var.hosted_zone_id != ""
  cognito_domain_prefix      = substr(replace("${local.name_prefix}-${data.aws_caller_identity.current.account_id}", "_", "-"), 0, 63)
  cognito_domain_host        = "${aws_cognito_user_pool_domain.admin.domain}.auth.${var.aws_region}.amazoncognito.com"
  admin_route_path           = "/admin"
  amplify_default_domain     = local.amplify_app_enabled ? aws_amplify_app.frontend[0].default_domain : null
  amplify_branch_domain      = local.amplify_app_enabled ? "${var.amplify_branch_name}.${local.amplify_default_domain}" : null
  admin_site_domain          = local.custom_domain_enabled ? local.site_domain : local.amplify_branch_domain
  derived_admin_redirect_uri = local.admin_site_domain != null && local.admin_site_domain != "" ? "https://${local.admin_site_domain}${local.admin_route_path}" : null
  admin_redirect_uri         = var.admin_redirect_override_url != "" ? var.admin_redirect_override_url : local.derived_admin_redirect_uri
  admin_callback_urls        = compact(["http://localhost:5173/admin", local.admin_redirect_uri])
  admin_logout_urls          = local.admin_callback_urls

  amplify_build_spec = var.frontend_build_spec != "" ? var.frontend_build_spec : <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - cd frontend
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: frontend/dist
        files:
          - '**/*'
      cache:
        paths:
          - frontend/node_modules/**/*
  EOT
}

data "archive_file" "site_api_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/leads-api/dist"
  output_path = "${path.module}/.terraform-build/${local.api_name}.zip"
}

resource "aws_cloudwatch_log_group" "site_api" {
  name              = "/aws/lambda/${local.api_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_dynamodb_table" "site_data" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.api_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.api_name}-dynamodb"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.site_data.arn
      }
    ]
  })
}

resource "aws_lambda_function" "site_api" {
  function_name    = local.api_name
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "nodejs20.x"
  handler          = "handler.handler"
  filename         = data.archive_file.site_api_zip.output_path
  source_code_hash = data.archive_file.site_api_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      LEADS_TABLE_NAME          = aws_dynamodb_table.site_data.name
      ENV_NAME                  = var.environment
      BUSINESS_NAME             = var.business_name
      SOURCE_SITE               = local.source_site
      ADMIN_EMAIL               = var.admin_email
      DEFAULT_SITE_CONTENT_JSON = var.site_content_json
    }
  }

  depends_on = [aws_cloudwatch_log_group.site_api]
  tags       = local.common_tags
}

resource "aws_cognito_user_pool" "admin" {
  name                     = "${local.name_prefix}-admins"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD", "EMAIL_OTP"]
  }

  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "admin" {
  name                                 = "${local.name_prefix}-admin-client"
  user_pool_id                         = aws_cognito_user_pool.admin.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = local.admin_callback_urls
  logout_urls                          = local.admin_logout_urls
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_USER_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "admin" {
  domain       = local.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.admin.id
}

resource "aws_cognito_user" "admin" {
  user_pool_id   = aws_cognito_user_pool.admin.id
  username       = lower(var.admin_email)
  message_action = "SUPPRESS"

  attributes = {
    email          = lower(var.admin_email)
    email_verified = "true"
  }
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.api_name}-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["authorization", "content-type"]
    allow_methods = ["GET", "OPTIONS", "POST", "PUT"]
    allow_origins = ["*"]
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.site_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "admin" {
  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name_prefix}-admin-jwt"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.admin.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.admin.id}"
  }
}

resource "aws_apigatewayv2_route" "get_site_content" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /site-content"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "post_leads" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /leads"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "put_admin_site_content" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "PUT /admin/site-content"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.admin.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.site_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_amplify_app" "frontend" {
  count = local.amplify_app_enabled ? 1 : 0

  name         = local.name_prefix
  repository   = local.amplify_repository_enabled ? local.amplify_repository_url : null
  access_token = local.amplify_repository_enabled && local.amplify_access_token != "" ? local.amplify_access_token : null
  platform     = "WEB"
  build_spec   = local.amplify_build_spec

  environment_variables = {
    VITE_API_BASE_URL      = aws_apigatewayv2_stage.default.invoke_url
    VITE_ENV_NAME          = var.environment
    VITE_SITE_NAME         = var.business_name
    VITE_SITE_CONTENT_JSON = var.site_content_json
    VITE_ADMIN_ROUTE_PATH  = local.admin_route_path
  }

  enable_auto_branch_creation = false
  tags                        = local.common_tags
}

resource "aws_amplify_branch" "frontend" {
  count = local.amplify_repository_enabled ? 1 : 0

  app_id            = aws_amplify_app.frontend[0].id
  branch_name       = var.amplify_branch_name
  stage             = local.sanitized_env_name == "prod" ? "PRODUCTION" : "DEVELOPMENT"
  framework         = "React"
  enable_auto_build = true

  environment_variables = {
    VITE_API_BASE_URL         = aws_apigatewayv2_stage.default.invoke_url
    VITE_ENV_NAME             = var.environment
    VITE_SITE_NAME            = var.business_name
    VITE_SITE_CONTENT_JSON    = var.site_content_json
    VITE_ADMIN_ROUTE_PATH     = local.admin_route_path
    VITE_COGNITO_DOMAIN       = local.cognito_domain_host
    VITE_COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.admin.id
    VITE_COGNITO_REDIRECT_URI = local.admin_redirect_uri
    VITE_COGNITO_LOGOUT_URI   = local.admin_redirect_uri
  }
}

resource "aws_amplify_domain_association" "custom_domain" {
  count = local.custom_domain_enabled ? 1 : 0

  app_id      = aws_amplify_app.frontend[0].id
  domain_name = var.root_domain

  sub_domain {
    branch_name = aws_amplify_branch.frontend[0].branch_name
    prefix      = var.subdomain
  }
}

resource "aws_route53_record" "amplify_subdomain" {
  count = local.custom_domain_enabled ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = local.site_domain
  type    = "CNAME"
  ttl     = 300
  records = [
    one([
      for subdomain in aws_amplify_domain_association.custom_domain[0].sub_domain :
      subdomain.dns_record
      if subdomain.prefix == var.subdomain
    ])
  ]
}
