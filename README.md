# StartupKit Landing Pages

Reusable starter repository for launching branded market-research landing pages per business. Each deployment is intended to own its own frontend configuration, API endpoint, Lambda function, and DynamoDB lead table while keeping the codebase reusable.

## Architecture

- `frontend/`: Vite + React + TypeScript + Tailwind landing page
- `backend/leads-api/`: TypeScript Lambda for `POST /leads`
- `infra/`: Terraform root module for DynamoDB, Lambda, API Gateway, and Amplify
- `infra/env/dev/`: environment entrypoint with business-specific variables

Request flow:

1. A visitor submits the lead form in the landing page.
2. The frontend sends the payload to `POST /leads` on API Gateway.
3. API Gateway invokes the Lambda function.
4. Lambda validates the request, rejects spam honeypot submissions, tags the lead with business context, and stores it in DynamoDB.

The browser never talks directly to DynamoDB.

## Repository Structure

```text
.
|-- frontend/
|   |-- src/
|   |   |-- components/
|   |   `-- config/
|-- backend/
|   `-- leads-api/
|       `-- src/
`-- infra/
    |-- env/
    |   `-- dev/
    `-- modules/
```

## Frontend Configuration

The landing page is environment-driven. Copy [frontend/.env.example](/C:/Users/chris/Documents/Business/software/startupkit/frontend/.env.example) to `frontend/.env.local` and set:

- `VITE_SITE_NAME`
- `VITE_HERO_TITLE`
- `VITE_HERO_SUBTITLE`
- `VITE_CTA_TEXT`
- `VITE_API_BASE_URL`
- `VITE_ENV_NAME`
- `VITE_HERO_IMAGE_URL`
- `VITE_SECTION_IMAGE_URL`
- `VITE_BRAND_COLOR`
- `VITE_FEATURE_1_TITLE`
- `VITE_FEATURE_1_DESCRIPTION`
- `VITE_FEATURE_2_TITLE`
- `VITE_FEATURE_2_DESCRIPTION`
- `VITE_FEATURE_3_TITLE`
- `VITE_FEATURE_3_DESCRIPTION`

The typed config loader lives in [frontend/src/config/siteConfig.ts](/C:/Users/chris/Documents/Business/software/startupkit/frontend/src/config/siteConfig.ts).

## Local Development

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

```bash
cd backend/leads-api
npm install
npm run build
```

The Lambda build bundles the handler into `backend/leads-api/dist/handler.js`, which is the artifact Terraform packages.

Local backend environment variables are documented in [backend/leads-api/.env.example](/C:/Users/chris/Documents/Business/software/startupkit/backend/leads-api/.env.example):

- `LEADS_TABLE_NAME`
- `ENV_NAME`
- `BUSINESS_NAME`
- `SOURCE_SITE`

## What Is Implemented

- Configurable landing page with hero, image, features, CTA, and lead form
- Loading, success, and error states on the frontend form
- Honeypot field for simple spam prevention
- Lambda request validation and email normalization
- DynamoDB persistence with tagged lead records
- Terraform-managed DynamoDB table, Lambda, IAM, CloudWatch log group, HTTP API, and optional Amplify app/domain association

Stored lead shape:

- `pk = LEAD#{email}`
- `sk = {created_at}#{request_id}`
- `email`
- `first_name`
- `last_name`
- `phone`
- `message`
- `env_name`
- `business_name`
- `source_site`
- `created_at`

## Terraform Deployment

The first environment entrypoint is [infra/env/dev](/C:/Users/chris/Documents/Business/software/startupkit/infra/env/dev).

1. Build the Lambda bundle first:

```bash
cd backend/leads-api
npm install
npm run build
```

2. Populate a tfvars file from [infra/env/dev/terraform.tfvars.example](/C:/Users/chris/Documents/Business/software/startupkit/infra/env/dev/terraform.tfvars.example). The example is prefilled for `Northstar Market Intelligence` and already points at `https://github.com/christopherclemmons/startupkit.git`.

3. Initialize and apply Terraform:

```bash
cd infra/env/dev
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

Important manual values:

- `amplify_repository_url`: required if you want Terraform to create Amplify
- `amplify_access_token`: required for Git-based Amplify providers that need a PAT
- `root_domain`, `hosted_zone_id`, and `enable_custom_domain`: required only for custom domain association

Key variables:

- `app_name`
- `environment`
- `business_name`
- `subdomain`
- `root_domain`
- `aws_region`
- `hero_title`
- `hero_subtitle`
- `cta_text`
- `hero_image_url`
- `section_image_url`
- `brand_color`
- feature title and description variables

Outputs include:

- `api_url`
- `amplify_app_id`
- `amplify_default_domain`
- `dynamodb_table_name`
- `custom_domain_url`

## Example Deployment Flow

Business A:

1. Set `business_name = "Northstar Market Intelligence"`.
2. Set `environment = "northstar-dev"`.
3. Set `subdomain = "northstar"`.
4. Set the landing page copy and images for Northstar.
5. Build the Lambda and apply Terraform.

Business B:

1. Copy the dev tfvars file.
2. Change `business_name`, `environment`, `subdomain`, and branded content variables.
3. Point Amplify env vars or branch settings at the new business values.
4. Apply again into the target environment.

No frontend code rewrite should be required for the next business if the content model stays within the current config surface.

## Quickest Test Path

Fastest local UI check:

1. Copy `frontend/.env.example` to `frontend/.env.local`.
2. From `frontend/`, run `npm install` and `npm run dev`.
3. Open the local Vite URL and verify the Northstar-branded page renders.

Fastest full-stack smoke test in AWS:

1. From `backend/leads-api/`, run `npm install` and `npm run build`.
2. Copy `infra/env/dev/terraform.tfvars.example` to `infra/env/dev/terraform.tfvars`.
3. Set a real `amplify_access_token` if you want Amplify created automatically. If you want the quickest backend-only test, leave Amplify enabled only after you have that token.
4. From `infra/env/dev/`, run `terraform init`, `terraform plan`, and `terraform apply`.
5. Copy the `api_url` output.
6. Set `VITE_API_BASE_URL` in `frontend/.env.local` to that `api_url`.
7. Run `npm run dev` in `frontend/` and submit the form.

Fastest backend-only API test after Terraform apply:

```bash
curl -X POST "$API_URL/leads" \
  -H "Content-Type: application/json" \
  -d "{\"first_name\":\"Chris\",\"email\":\"chris@example.com\",\"business_interest\":\"Testing the landing flow\"}"
```

If the API is working, you should get a `201` response and the lead should be written to the DynamoDB table named in the Terraform outputs.

## Next Practical Work

- add test coverage for frontend form behavior and backend validation paths
- add prod environment entrypoint under `infra/env/prod`
- decide whether to retire the older legacy `src/` and previous Terraform trees that still exist in the repository
- add CI to build `frontend/` and `backend/leads-api/` before infrastructure deployment
