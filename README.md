# StartupKit Landing Pages

Reusable starter for launching branded market-validation landing pages where each site keeps its own:

- public landing page content
- hidden admin login
- protected admin editor route
- API endpoint
- tagged lead records
- DynamoDB-backed site content document

The public site has no visible admin links. The admin editor lives at `/admin` and is intended for one Cognito-managed email identity per deployment.

## Architecture

- `frontend/`: Vite + React + TypeScript + Tailwind landing page and hidden admin editor
- `backend/leads-api/`: TypeScript Lambda behind API Gateway
- `infra/`: Terraform for DynamoDB, Lambda, API Gateway, Cognito, Amplify, and optional Route53 wiring
- `infra/env/dev/`: example environment entrypoint

Request flow:

1. Public visitors load `GET /site-content`.
2. The page renders the site-specific content document for that deployment.
3. Lead submissions go to `POST /leads`.
4. Lambda validates the payload and stores the lead in DynamoDB with `env_name`, `business_name`, and `source_site`.
5. The hidden admin route uses Cognito-managed sign-in and calls `PUT /admin/site-content`.
6. Lambda updates the same site’s content document in DynamoDB.

The browser never talks directly to DynamoDB.

## Content Model

The repo now treats landing page copy as a single JSON DTO. That keeps the data model consistent across sites and makes it easy to edit or duplicate.

Current DTO shape:

```json
{
  "site_name": "Northstar Market Intelligence",
  "business_name": "Northstar Market Intelligence",
  "env_name": "northstar-dev",
  "source_site": "northstar.example.com",
  "brand_color": "#0f766e",
  "page_title": "Northstar Market Intelligence | Research Landing Page",
  "meta_description": "Launch branded research landing pages quickly.",
  "hero_title": "Pressure-test your next product idea",
  "hero_subtitle": "Launch a focused research landing page.",
  "cta_text": "Join the pilot list",
  "hero_image_url": "https://example.com/hero.jpg",
  "section_image_url": "https://example.com/section.jpg",
  "features": [
    { "id": "feature-1", "title": "Feature title", "description": "Feature body" }
  ],
  "faqs": [
    { "id": "faq-1", "question": "Question?", "answer": "Answer." }
  ]
}
```

This document is:

- passed into the frontend as a default/fallback via `VITE_SITE_CONTENT_JSON`
- used by Lambda as the default content when no saved record exists yet
- saved per site through the admin route into DynamoDB

## DynamoDB Records

The table is shared by that deployment only and uses two record types.

Lead item:

- `pk = LEAD#{email}`
- `sk = {created_at}#{request_id}`
- `entity_type = LEAD`
- `site_pk = SITE#{env_name}`
- `email`
- `first_name`
- `last_name`
- `phone`
- `message`
- `env_name`
- `business_name`
- `source_site`
- `created_at`

Site content item:

- `pk = SITE#{env_name}`
- `sk = CONTENT#CURRENT`
- `entity_type = SITE_CONTENT`
- `site_name`
- `business_name`
- `env_name`
- `source_site`
- `content`
- `content_version`
- `created_at`
- `updated_at`
- `updated_by`

That keeps Site A content separate from Site B content, even though both use the same repository pattern.

## Hidden Admin Access

The site exposes no public navigation to admin tools.

- Hidden route: `/admin`
- Auth provider: Cognito user pool per deployment
- Intended admin identity: one email address configured with `admin_email`
- Protected API route: `PUT /admin/site-content`

The frontend uses Cognito’s managed login flow and stores the returned ID token in `sessionStorage` for the current browser session.

## Local Development

### Frontend

Copy [frontend/.env.example](/C:/Users/chris/Documents/Business/software/startupkit/frontend/.env.example) to `frontend/.env.local`.

Key frontend variables:

- `VITE_API_BASE_URL`
- `VITE_ENV_NAME`
- `VITE_SITE_NAME`
- `VITE_SITE_CONTENT_JSON`
- `VITE_ADMIN_ROUTE_PATH`
- `VITE_COGNITO_DOMAIN`
- `VITE_COGNITO_CLIENT_ID`
- `VITE_COGNITO_REDIRECT_URI`
- `VITE_COGNITO_LOGOUT_URI`

Run:

```bash
cd frontend
npm install
npm run dev
```

Public page: `http://localhost:5173/`

Hidden admin route: `http://localhost:5173/admin`

### Backend

Backend env example: [backend/leads-api/.env.example](/C:/Users/chris/Documents/Business/software/startupkit/backend/leads-api/.env.example)

Key backend variables:

- `LEADS_TABLE_NAME`
- `ENV_NAME`
- `BUSINESS_NAME`
- `SOURCE_SITE`
- `ADMIN_EMAIL`
- `DEFAULT_SITE_CONTENT_JSON`

Run:

```bash
cd backend/leads-api
npm install
npm run build
```

The Lambda bundle is emitted to `backend/leads-api/dist/handler.js`.

## Terraform Deployment

Primary example entrypoint: [infra/env/dev](/C:/Users/chris/Documents/Business/software/startupkit/infra/env/dev)

### Main variables

- `app_name`
- `environment`
- `business_name`
- `admin_email`
- `subdomain`
- `root_domain`
- `aws_region`
- `site_content_json`
- `admin_redirect_override_url`
- `enable_amplify_app`
- `amplify_branch_name`
- `amplify_repository_url`
- `enable_custom_domain`
- `tags`

### What Terraform creates

- DynamoDB table for site data and leads
- Lambda function for public/admin API actions
- IAM role and DynamoDB permissions for Lambda
- API Gateway HTTP API
- Cognito user pool
- Cognito app client
- Cognito hosted domain
- single Cognito user for the configured admin email
- Amplify app and branch configuration
- optional Route53 record for the site subdomain

### Outputs

- `api_url`
- `amplify_app_id`
- `amplify_default_domain`
- `cognito_user_pool_id`
- `cognito_user_pool_client_id`
- `cognito_domain`
- `dynamodb_table_name`
- `custom_domain_url`

### Deploy flow

1. Build the Lambda bundle.

```bash
cd backend/leads-api
npm install
npm run build
```

2. Copy [infra/env/dev/terraform.tfvars.example](/C:/Users/chris/Documents/Business/software/startupkit/infra/env/dev/terraform.tfvars.example) to `infra/env/dev/terraform.tfvars`.

3. Set the site-specific values:

- business identity
- admin email
- custom domain/subdomain
- callback/logout URLs for `/admin`
- `site_content_json`

4. Apply Terraform.

```bash
cd infra/env/dev
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

### Important Cognito note

This Terraform config derives the Cognito callback and logout URLs for the hidden admin route automatically.

- Local development always allows `http://localhost:5173/admin`.
- Without a custom domain, the redirect target is `https://<amplify_branch_name>.<amplify_default_domain>/admin`.
- With `enable_custom_domain = true`, the redirect target becomes `https://<subdomain>.<root_domain>/admin`.
- If you need a bootstrap workaround, set `admin_redirect_override_url` to a fixed URL and Terraform will use that instead.

If you deploy another business, give that deployment its own `admin_email`. The callback and logout URLs follow that deployment automatically.

## Business A / Business B Example

Business A:

- `environment = "business-a"`
- `business_name = "Business A"`
- `subdomain = "business-a"`
- `site_content_json` contains Business A copy and questions
- admin logs into `https://business-a.example.com/admin`
- all saved content and leads are tagged with Business A context

Business B:

- `environment = "business-b"`
- `business_name = "Business B"`
- `subdomain = "business-b"`
- `site_content_json` contains Business B copy and questions
- admin logs into `https://business-b.example.com/admin`
- content does not overlap with Business A because the site key is different

No frontend code rewrite is required between those deployments if the DTO shape stays the same.

## API Summary

Public:

- `GET /site-content`
- `POST /leads`

Protected:

- `PUT /admin/site-content`

Example lead test:

```bash
curl -X POST "$API_URL/leads" \
  -H "Content-Type: application/json" \
  -d "{\"first_name\":\"Chris\",\"email\":\"chris@example.com\",\"business_interest\":\"Testing the landing flow\"}"
```

## Validation Performed

- `npm run build` in `backend/leads-api`
- `npm run build` in `frontend`
- `terraform -chdir=infra init -backend=false -input=false`
- `terraform -chdir=infra validate`

## Practical Notes

- The hidden admin route is implemented client-side and intentionally not linked from the public page.
- The API falls back to `DEFAULT_SITE_CONTENT_JSON` until you save site content through the admin route for the first time.
- After the first admin save, the live site content comes from DynamoDB for that site.
- Existing unrelated repo folders were left alone unless needed for this flow.
