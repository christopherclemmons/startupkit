variable "app_name" {
  type    = string
  default = "startupkit"
}
variable "environment" {
  type    = string
  default = "northstar-dev"
}
variable "business_name" {
  type    = string
  default = "Northstar Market Intelligence"
}
variable "admin_email" {
  type    = string
  default = "christopher.clemmons2020@gmail.com"
}
variable "subdomain" {
  type    = string
  default = "northstar"
}
variable "root_domain" {
  type    = string
  default = ""
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "site_content_json" {
  type    = string
  default = <<-EOT
  {
    "site_name": "Northstar Market Intelligence",
    "business_name": "Northstar Market Intelligence",
    "env_name": "northstar-dev",
    "source_site": "northstar.example.com",
    "brand_color": "#0f766e",
    "page_title": "Northstar Market Intelligence | Research Landing Page",
    "meta_description": "Launch branded research landing pages quickly, capture leads, and route them through a dedicated backend API.",
    "hero_title": "Pressure-test your next product idea with qualified operator feedback",
    "hero_subtitle": "Launch a focused research landing page, capture high-intent interest, and learn which positioning gets busy decision-makers to respond.",
    "cta_text": "Join the pilot list",
    "hero_image_url": "https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=1200&q=80",
    "section_image_url": "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80",
    "features": [
      {
        "id": "feature-1",
        "title": "Audience signal capture",
        "description": "Identify whether founders, operators, and analysts actually engage with your core market narrative."
      },
      {
        "id": "feature-2",
        "title": "Dedicated lead pipeline",
        "description": "Route every submission through a backend API that tags leads with the environment and business identity."
      },
      {
        "id": "feature-3",
        "title": "Reusable campaign system",
        "description": "Duplicate the launch pattern for the next business by changing configuration instead of rewriting application code."
      }
    ],
    "faqs": [
      {
        "id": "faq-1",
        "question": "How is this landing page reused for another business?",
        "answer": "Update the seeded site content JSON, deploy the site, and use the hidden admin route for future content edits."
      },
      {
        "id": "faq-2",
        "question": "Where do submitted leads go?",
        "answer": "The frontend posts to the campaign API endpoint, which invokes Lambda. Lambda validates the payload, tags the lead with env and business context, and writes it to DynamoDB."
      },
      {
        "id": "faq-3",
        "question": "Can I change the questions per deployment?",
        "answer": "Yes. Each site has its own content record in DynamoDB, so Site A and Site B can keep different FAQs and copy without sharing content."
      }
    ]
  }
  EOT
}
variable "admin_redirect_override_url" {
  type    = string
  default = ""
}
variable "enable_amplify_app" {
  type    = bool
  default = true
}
variable "amplify_repository_url" {
  type    = string
  default = "https://github.com/christopherclemmons/startupkit"
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
  type = map(string)
  default = {
    project = "market-validation"
    owner   = "christopher-clemmons"
  }
}
