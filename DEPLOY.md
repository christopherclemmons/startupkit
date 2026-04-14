# Dev Three-Tier Deploy (Single-Instance Test)

This stack deploys a testable dev environment with:
- S3 + CloudFront frontend hosting
- Public ALB for API traffic
- ECS Fargate backend service (stateless)
- RDS PostgreSQL (private subnet, non-public)

Notes for this test profile:
- ECS backend service is pinned to the first public subnet.
- ALB still uses two public subnets because AWS ALB requires at least two AZ subnets.
- Backend desired count defaults to `0` so first apply succeeds before the image is pushed.

## 1) Provision infrastructure

From repo root:

```powershell
$env:TF_VAR_db_password = "<set-a-strong-password>"

terraform -chdir=infra/dev init
terraform -chdir=infra/dev apply -auto-approve
```

Important: Steps 2-4 depend on Terraform outputs. If apply fails, stop and fix that first.

### Recover from orphaned resources (after failed/incomplete destroy)

If Terraform reports `AlreadyExists` errors for dev resources (for example DB subnet group, S3 bucket, or CloudFront OAC), import the existing AWS resources into state:

```bash
chmod +x infra/dev/import_orphaned_resources.sh
./infra/dev/import_orphaned_resources.sh
terraform -chdir=infra/dev plan
```

The script safely skips resources already tracked in state and also imports the RDS instance / CloudFront distribution if they still exist.
For full script usage details and optional arguments, see [`infra/dev/README.md`](infra/dev/README.md).

## 2) Build and push backend image to ECR

```powershell
$region = terraform -chdir=infra/dev output -no-color -raw aws_region
$backendRepo = terraform -chdir=infra/dev output -no-color -raw backend_ecr_repository_url

if ([string]::IsNullOrWhiteSpace($region) -or [string]::IsNullOrWhiteSpace($backendRepo)) {
  throw "Terraform outputs are empty. Run 'terraform -chdir=infra/dev apply -auto-approve' successfully first."
}

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $backendRepo.Split('/')[0]

docker build -t "${backendRepo}:latest" -f src/backend/API/Dockerfile src/backend
docker push "${backendRepo}:latest"
```

## 3) Frontend deployment note

The repository frontend is now a Next.js application with server-rendered pages and a
server-side backend proxy. The current Terraform frontend module still provisions static
S3 + CloudFront hosting, which is not compatible with this frontend runtime.

Before using the AWS deployment flow, replace the static frontend hosting module with a
server-capable deployment target such as ECS/Fargate, App Runner, or another Node.js
runtime behind CloudFront/ALB.

For local verification, use:

```powershell
docker compose -f docker-compose.yml up -d --build
```

## 4) Start backend service

```powershell
terraform -chdir=infra/dev apply -var service_desired_count=1
```

Then open:

```powershell
terraform -chdir=infra/dev output -raw frontend_url
```

## 5) Connect to private PostgreSQL from your machine (SSM tunnel)

```powershell
$dbHost = terraform -chdir=infra/dev output -raw database_endpoint
$instanceId = terraform -chdir=infra/dev output -raw database_tunnel_instance_id

# Keep this running in terminal #1
aws ssm start-session `
  --target $instanceId `
  --document-name AWS-StartPortForwardingSessionToRemoteHost `
  --parameters "{\"host\":[\"$dbHost\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5432\"]}"
```

If you get `Session Manager plugin not found`, install it first:
- Windows (winget): `winget install --id Amazon.SessionManagerPlugin --source winget`
- Verify: `session-manager-plugin --version`
- Official guide: <https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html>

Then connect your SQL client to:
- Host: `localhost`
- Port: `5432`
- Database: `app` (or your configured `db_name`)
- Username/password: your Terraform `db_username` / `db_password`

## Production backend security switches

For production, enable security settings during apply:

```powershell
terraform -chdir=infra/dev apply -auto-approve `
  -var "security_require_authentication=true" `
  -var "security_enable_https_redirection=true" `
  -var "security_jwt_authority=https://<your-oidc-authority>" `
  -var "security_jwt_audience=<your-api-audience>" `
  -var "security_rate_limit_permit_limit=60" `
  -var "security_rate_limit_window_seconds=60"
```

And ensure:
- `CORS_ALLOWED_ORIGINS=https://<your-frontend-domain>`
- HTTPS is enabled end-to-end before turning on redirect.


