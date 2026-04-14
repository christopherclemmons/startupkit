module "landing_page" {
  source = "../.."

  app_name                    = var.app_name
  environment                 = var.environment
  business_name               = var.business_name
  admin_email                 = var.admin_email
  subdomain                   = var.subdomain
  root_domain                 = var.root_domain
  aws_region                  = var.aws_region
  site_content_json           = var.site_content_json
  admin_redirect_override_url = var.admin_redirect_override_url
  enable_amplify_app          = var.enable_amplify_app
  amplify_repository_url      = var.amplify_repository_url
  amplify_access_token        = var.amplify_access_token
  amplify_branch_name         = var.amplify_branch_name
  enable_custom_domain        = var.enable_custom_domain
  hosted_zone_id              = var.hosted_zone_id
  frontend_build_spec         = var.frontend_build_spec
  tags                        = var.tags
}
