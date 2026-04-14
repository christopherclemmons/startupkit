variable "app_name" {
  description = "Base application name used for resource naming."
  type        = string
  default     = "startupkit"
}

variable "environment" {
  description = "Deployment environment or campaign identifier."
  type        = string
  default     = "dev"
}

variable "business_name" {
  description = "Display name for the business tied to this deployment."
  type        = string
  default     = "Northstar Market Intelligence"
}

variable "admin_email" {
  description = "Single admin email allowed to manage the hidden site editor."
  type        = string
  default     = "christopher.clemmons2020@gmail.com"
}

variable "subdomain" {
  description = "Subdomain for the landing page, such as business-a."
  type        = string
  default     = "northstar"
}

variable "root_domain" {
  description = "Root domain for optional custom domain setup."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "site_content_json" {
  description = "JSON document that defines the default landing page content DTO for this site."
  type        = string
  default     = <<-EOT
  {
    "site_name": "Northstar Market Intelligence",
    "business_name": "Northstar Market Intelligence",
    "env_name": "dev",
    "source_site": "northstar",
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
  description = "Optional explicit admin redirect URL to use for Cognito bootstrap instead of deriving from Amplify or the custom domain."
  type        = string
  default     = ""
}

variable "amplify_repository_url" {
  description = "Repository URL connected to Amplify. Defaults to the shared startupkit repository."
  type        = string
  default     = "https://github.com/christopherclemmons/startupkit"
}

variable "enable_amplify_app" {
  description = "Whether to create the Amplify app resource."
  type        = bool
  default     = true
}

variable "amplify_access_token" {
  description = "Optional GitHub personal access token used by Amplify to connect the repository on initial creation or reconnect. Leave empty to create the Amplify app without a repo connection."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition = (
      trimspace(var.amplify_access_token) == "" ||
      trimspace(var.amplify_access_token) != "replace-with-amplify-access-token-or-leave-empty"
    )
    error_message = "Set amplify_access_token to a real GitHub token or leave it empty. Do not leave the example placeholder value in place."
  }
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
  default = {
    project = "market-validation"
    owner   = "christopher-clemmons"
  }
}
