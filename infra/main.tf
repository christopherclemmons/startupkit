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

locals {
  sanitized_app_name = replace(lower(var.app_name), "/[^a-z0-9-]/", "-")
  sanitized_env_name = replace(lower(var.environment), "/[^a-z0-9-]/", "-")
  name_prefix        = trimsuffix("${local.sanitized_app_name}-${local.sanitized_env_name}", "-")
  api_name           = "${local.name_prefix}-leads-api"
  table_name         = "${local.name_prefix}-leads"
  site_domain        = var.enable_custom_domain && var.root_domain != "" ? "${var.subdomain}.${var.root_domain}" : ""

  common_tags = merge(
    {
      AppName      = var.app_name
      Environment  = var.environment
      BusinessName = var.business_name
      ManagedBy    = "terraform"
    },
    var.tags,
  )

  amplify_enabled       = var.amplify_repository_url != ""
  custom_domain_enabled = local.amplify_enabled && var.enable_custom_domain && var.root_domain != "" && var.hosted_zone_id != ""

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

data "archive_file" "leads_api_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/leads-api/dist"
  output_path = "${path.module}/.terraform-build/${local.api_name}.zip"
}

resource "aws_cloudwatch_log_group" "leads_api" {
  name              = "/aws/lambda/${local.api_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_dynamodb_table" "leads" {
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
        Action = ["dynamodb:PutItem"]
        Effect = "Allow"
        Resource = aws_dynamodb_table.leads.arn
      }
    ]
  })
}

resource "aws_lambda_function" "leads_api" {
  function_name    = local.api_name
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "nodejs20.x"
  handler          = "handler.handler"
  filename         = data.archive_file.leads_api_zip.output_path
  source_code_hash = data.archive_file.leads_api_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      LEADS_TABLE_NAME = aws_dynamodb_table.leads.name
      ENV_NAME         = var.environment
      BUSINESS_NAME    = var.business_name
      SOURCE_SITE      = local.custom_domain_enabled ? local.site_domain : var.subdomain
    }
  }

  depends_on = [aws_cloudwatch_log_group.leads_api]
  tags       = local.common_tags
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.api_name}-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["OPTIONS", "POST"]
    allow_origins = ["*"]
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.leads_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_leads" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /leads"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "options_leads" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "OPTIONS /leads"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
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
  function_name = aws_lambda_function.leads_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_amplify_app" "frontend" {
  count = local.amplify_enabled ? 1 : 0

  name         = local.name_prefix
  repository   = var.amplify_repository_url
  access_token = var.amplify_access_token != "" ? var.amplify_access_token : null
  platform     = "WEB"
  build_spec   = local.amplify_build_spec

  environment_variables = {
    VITE_SITE_NAME             = var.business_name
    VITE_HERO_TITLE            = var.hero_title
    VITE_HERO_SUBTITLE         = var.hero_subtitle
    VITE_CTA_TEXT              = var.cta_text
    VITE_API_BASE_URL          = aws_apigatewayv2_stage.default.invoke_url
    VITE_ENV_NAME              = var.environment
    VITE_HERO_IMAGE_URL        = var.hero_image_url
    VITE_SECTION_IMAGE_URL     = var.section_image_url
    VITE_BRAND_COLOR           = var.brand_color
    VITE_FEATURE_1_TITLE       = var.feature_1_title
    VITE_FEATURE_1_DESCRIPTION = var.feature_1_description
    VITE_FEATURE_2_TITLE       = var.feature_2_title
    VITE_FEATURE_2_DESCRIPTION = var.feature_2_description
    VITE_FEATURE_3_TITLE       = var.feature_3_title
    VITE_FEATURE_3_DESCRIPTION = var.feature_3_description
  }

  enable_auto_branch_creation = false
  tags                        = local.common_tags
}

resource "aws_amplify_branch" "frontend" {
  count = local.amplify_enabled ? 1 : 0

  app_id            = aws_amplify_app.frontend[0].id
  branch_name       = var.amplify_branch_name
  stage             = local.sanitized_env_name == "prod" ? "PRODUCTION" : "DEVELOPMENT"
  framework         = "React"
  enable_auto_build = true

  environment_variables = {
    VITE_SITE_NAME             = var.business_name
    VITE_HERO_TITLE            = var.hero_title
    VITE_HERO_SUBTITLE         = var.hero_subtitle
    VITE_CTA_TEXT              = var.cta_text
    VITE_API_BASE_URL          = aws_apigatewayv2_stage.default.invoke_url
    VITE_ENV_NAME              = var.environment
    VITE_HERO_IMAGE_URL        = var.hero_image_url
    VITE_SECTION_IMAGE_URL     = var.section_image_url
    VITE_BRAND_COLOR           = var.brand_color
    VITE_FEATURE_1_TITLE       = var.feature_1_title
    VITE_FEATURE_1_DESCRIPTION = var.feature_1_description
    VITE_FEATURE_2_TITLE       = var.feature_2_title
    VITE_FEATURE_2_DESCRIPTION = var.feature_2_description
    VITE_FEATURE_3_TITLE       = var.feature_3_title
    VITE_FEATURE_3_DESCRIPTION = var.feature_3_description
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
