variable "app_name" {
  description = "Base application name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment or campaign identifier."
  type        = string
}

variable "business_name" {
  description = "Display name for the business tied to this deployment."
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the landing page, such as business-a."
  type        = string
}

variable "root_domain" {
  description = "Root domain for optional custom domain setup."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
}

variable "hero_title" {
  description = "Landing page hero headline."
  type        = string
}

variable "hero_subtitle" {
  description = "Landing page hero subtitle."
  type        = string
}

variable "cta_text" {
  description = "Call-to-action text."
  type        = string
}

variable "hero_image_url" {
  description = "Hero image URL for the landing page."
  type        = string
}

variable "section_image_url" {
  description = "Supporting section image URL."
  type        = string
}

variable "brand_color" {
  description = "Brand accent color used by the landing page."
  type        = string
}

variable "feature_1_title" { type = string }
variable "feature_1_description" { type = string }
variable "feature_2_title" { type = string }
variable "feature_2_description" { type = string }
variable "feature_3_title" { type = string }
variable "feature_3_description" { type = string }

variable "amplify_repository_url" {
  description = "Repository URL connected to Amplify. Leave blank to skip app creation."
  type        = string
  default     = ""
}

variable "amplify_access_token" {
  description = "Personal access token for Amplify Git provider integration when required."
  type        = string
  default     = ""
  sensitive   = true
}

variable "amplify_branch_name" {
  description = "Git branch Amplify should build for this environment."
  type        = string
  default     = "main"
}

variable "enable_custom_domain" {
  description = "Whether to connect the Amplify app to a custom domain."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Optional Route53 hosted zone ID for custom domain support."
  type        = string
  default     = ""
}

variable "frontend_build_spec" {
  description = "Optional custom Amplify build spec."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
