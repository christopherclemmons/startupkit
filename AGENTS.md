You are a senior full-stack cloud engineer. Build a production-ready starter repository for rapidly launching market-research landing pages.

## Goal
Create a reusable repo that lets me quickly deploy branded landing pages for different businesses using configuration variables. Each deployment should automatically provision and connect to its own AWS resources and branding.

## Core use case
I want to deploy landing pages for different businesses, such as:
- business A
- business B
- business C

Each deployment should:
- render the landing page with that business's branding/content
- deploy to its own subdomain
- send leads to its own backend
- store leads in its own DynamoDB table
- tag each lead with the environment/business name
- be easy to spin up again for the next landing page with minimal changes

## Technical stack
Use:
- Vite
- React
- TypeScript
- Tailwind CSS
- AWS Amplify for frontend hosting
- AWS Lambda for backend form submission
- API Gateway for HTTP endpoint
- DynamoDB for lead storage
- Terraform for infrastructure

## Important architecture rule
Do NOT have the frontend call DynamoDB directly.
The frontend must submit leads to an HTTP API endpoint.
The API endpoint should invoke Lambda, and Lambda writes to DynamoDB.

## What to build

### 1. Frontend landing page
Build a clean landing page with:
- no top navigation links
- hero section
- image section
- features section
- CTA section
- lead capture form

The lead form should capture:
- first_name
- last_name (optional)
- email
- phone (optional)
- business_interest or message (optional)

When submitted, the form should POST to the backend API.

### 2. Frontend branding/config system
The landing page content must be configurable through environment variables so I can reuse the repo for different businesses.

Use environment-based values for:
- site/business name
- headline
- subheadline
- CTA text
- feature titles/descriptions
- hero image URL
- section image URL
- brand color
- environment name
- API base URL

Example:
- VITE_SITE_NAME
- VITE_HERO_TITLE
- VITE_HERO_SUBTITLE
- VITE_CTA_TEXT
- VITE_ENV_NAME
- VITE_API_BASE_URL
- VITE_HERO_IMAGE_URL
- VITE_SECTION_IMAGE_URL

Create a typed config helper so the page reads from environment variables cleanly.

### 3. Backend API
Create a Lambda function that accepts lead submissions.

Requirements:
- validate input
- require email
- normalize email to lowercase
- store submitted leads in DynamoDB
- tag each lead with:
  - env_name
  - business_name
  - source_site
  - created_at
- return proper success/error responses
- include CORS support for Amplify frontend

Suggested DynamoDB item shape:
- pk = LEAD#{email}
- sk = timestamp or uuid
- email
- first_name
- last_name
- phone
- message
- env_name
- business_name
- source_site
- created_at

Use TypeScript for Lambda.

### 4. Terraform infrastructure
Create Terraform that provisions:
- DynamoDB table
- Lambda function
- IAM role/policies for Lambda
- API Gateway HTTP API
- Lambda permission for API Gateway
- Amplify app
- Amplify branch/environment configuration
- optional Route53 subdomain record if a hosted zone is provided

Terraform must support launching a new landing page via variables.

Create variables for:
- app_name
- environment
- business_name
- subdomain
- root_domain
- aws_region
- hero_title
- hero_subtitle
- cta_text
- hero_image_url
- section_image_url
- brand_color
- amplify_repository_url or placeholder
- enable_custom_domain
- tags

Terraform should generate unique resource names based on app_name/environment.

Example expectations:
- subdomain = business-a
- root_domain = example.com
- deployed URL = business-a.example.com
- DynamoDB table name = business-a-leads-dev
or similar naming convention

### 5. Lead tagging behavior
Each deployment must automatically tag leads by env/business context.

For example:
If I deploy for Business A:
- business_name = Business A
- environment = business-a
- table name includes business-a
- frontend shows Business A branding
- every lead stored includes business_name = Business A and env_name = business-a

If I deploy again for another business:
- no code rewrite should be required
- only config/variables should change

### 6. Repository design
Make this a reusable starter repo that is clean and easy to clone.

Suggested structure:

/
  frontend/
  backend/
    leads-api/
  infra/
    modules/
    env/
      dev/
      prod/
  README.md

### 7. Frontend implementation details
Use:
- React functional components
- Tailwind for styling
- clean reusable sections
- a simple modern SaaS/market research aesthetic
- mobile responsive layout
- loading and success/error states for form submission

### 8. Backend implementation details
Include:
- request DTO validation
- shared response helpers
- error handling
- clear separation of concerns
- environment variables for DynamoDB table and metadata

### 9. Terraform implementation details
Include:
- reusable modules where appropriate
- outputs for:
  - api_url
  - amplify_app_id
  - amplify_default_domain
  - dynamodb_table_name
  - custom_domain_url if enabled
- variables.tf
- outputs.tf
- main.tf
- terraform.tfvars.example

### 10. README
Write a practical README that explains:
- what this repo is for
- architecture overview
- how to run locally
- how to configure a new landing page
- how to deploy a new environment/business
- which variables to change
- how leads are stored/tagged
- how to connect a custom subdomain
- example deployment flow for Business A and Business B

## Local development requirements
Support local development with:
- frontend .env.example
- backend env example
- commands to run frontend locally
- commands to test Lambda locally if practical
- clear instructions for wiring frontend to deployed API

## Code quality requirements
- TypeScript everywhere possible
- clean naming
- no placeholder junk
- production-minded structure
- minimal but solid implementation
- secure defaults
- no direct DynamoDB access from the browser

## Deliverables
Generate:
1. full repository structure
2. starter code for frontend
3. starter code for backend Lambda
4. Terraform files
5. env examples
6. README
7. comments where setup requires manual values

## Nice to have
If practical, also include:
- simple spam prevention field (honeypot)
- basic email regex validation
- CloudWatch logging for Lambda
- Terraform tags on all resources
- reusable section data model for features
- easy way to duplicate content for future landing pages

Build this as if I want to reuse it over and over for fast market validation campaigns.

## Disclaimer
Feel free to restruct anything that preexisting since this repo is a clone from a repository with a totally differnent purpose.