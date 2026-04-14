variable "app_name" { type = string }
variable "environment" { type = string }
variable "business_name" { type = string }
variable "subdomain" { type = string }
variable "root_domain" {
  type    = string
  default = ""
}
variable "aws_region" { type = string }
variable "hero_title" { type = string }
variable "hero_subtitle" { type = string }
variable "cta_text" { type = string }
variable "hero_image_url" { type = string }
variable "section_image_url" { type = string }
variable "brand_color" { type = string }
variable "feature_1_title" { type = string }
variable "feature_1_description" { type = string }
variable "feature_2_title" { type = string }
variable "feature_2_description" { type = string }
variable "feature_3_title" { type = string }
variable "feature_3_description" { type = string }
variable "amplify_repository_url" {
  type    = string
  default = ""
}
variable "amplify_access_token" {
  type      = string
  default   = ""
  sensitive = true
}
variable "amplify_branch_name" {
  type    = string
  default = "main"
}
variable "enable_custom_domain" {
  type    = bool
  default = false
}
variable "hosted_zone_id" {
  type    = string
  default = ""
}
variable "frontend_build_spec" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
