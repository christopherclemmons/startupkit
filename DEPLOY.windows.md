# Dev Deploy (Windows PowerShell)

This guide deploys the dev environment with:
- Frontend: S3 + CloudFront
- API: ALB + ECS Fargate (.NET backend)
- Database: RDS PostgreSQL (private subnet, non-public)

## Prerequisites

Run these from the repo root in PowerShell:

```powershell
aws --version
docker --version
terraform version
npm --version
```

You must also be authenticated to AWS in the target account/region.

## 1) Provision infrastructure (required first)

```powershell
$env:TF_VAR_db_password = "<set-a-strong-password-for-the-database>"

terraform -chdir=infra/dev init
terraform -chdir=infra/dev apply -auto-approve
```

If `apply` fails, stop and fix that first. The next steps require Terraform outputs.

### Recover from orphaned resources (after failed/incomplete destroy)

If Terraform reports `AlreadyExists` errors for dev resources (for example DB subnet group, S3 bucket, or CloudFront OAC), run the recovery script from Git Bash or WSL:

```bash
chmod +x infra/dev/import_orphaned_resources.sh
./infra/dev/import_orphaned_resources.sh
terraform -chdir=infra/dev plan
```

For full script details and optional arguments, see [`infra/dev/README.md`](infra/dev/README.md).

## 2) Build and push backend image to ECR

Use this flow exactly from the repo root.

```powershell
$ErrorActionPreference = "Stop"
```



### 2.1 Get region and backend ECR URL from Terraform outputs

```powershell
$region = terraform -chdir=infra/dev output -no-color -raw aws_region
$backendRepo = terraform -chdir=infra/dev output -no-color -raw backend_ecr_repository_url

if ([string]::IsNullOrWhiteSpace($region) -or [string]::IsNullOrWhiteSpace($backendRepo)) {
  throw "Terraform outputs are empty. Re-run 'terraform -chdir=infra/dev apply -auto-approve'."
}
```

### 2.2 Verify AWS identity and that the repository exists

```powershell
# Replace with your AWS CLI profile name
$awsProfile = "<your-aws-profile>"

aws sts get-caller-identity --profile $awsProfile
$repoName = $backendRepo.Split('/')[-1]
aws ecr describe-repositories --repository-names $repoName --region $region --profile $awsProfile
```

### 2.3 Login to ECR (Windows-safe command)

```powershell
$registry = $backendRepo.Split('/')[0]

cmd.exe /c "aws ecr get-login-password --region $region --profile $awsProfile | docker login --username AWS --password-stdin $registry"
```

### 2.4 Build, tag, and push backend image

```powershell
# Build from the project root using the backend Dockerfile
docker build -t "$repoName`:latest" -f src/backend/API/Dockerfile src/backend

# Tag for ECR and push
docker tag "$repoName`:latest" "$backendRepo`:latest"
docker push "$backendRepo`:latest"
```

### Common errors

- `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.`
  Start Docker Desktop, then retry.
- `400 Bad Request` on `docker login`
  Ensure the correct profile is used and keep the `cmd.exe /c` login command above.


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

## 4) Start backend ECS service

```powershell
terraform -chdir=infra/dev apply -auto-approve -var service_desired_count=1
```

## 5) Open the app

```powershell
terraform -chdir=infra/dev output -no-color -raw frontend_url
```

## 6) Connect to private PostgreSQL from your machine (SSM tunnel)

```powershell
$dbHost = terraform -chdir=infra/dev output -no-color -raw database_endpoint
$instanceId = terraform -chdir=infra/dev output -no-color -raw database_tunnel_instance_id

# Keep this running in terminal #1
aws ssm start-session `
  --target $instanceId `
  --document-name AWS-StartPortForwardingSessionToRemoteHost `
  --parameters "{\"host\":[\"$dbHost\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5432\"]}"
```

### 6.1 Troubleshooting: `Session Manager plugin not found`

If you see an error like `SessionManagerPlugin is not found`, install the plugin and retry:

```powershell
# Option A: winget (recommended)
winget install --id Amazon.SessionManagerPlugin --source winget

# Option B: Chocolatey
choco install session-manager-plugin -y

# Verify install
session-manager-plugin --version
```

If `session-manager-plugin` is still not recognized:
- Close and reopen PowerShell, then run `session-manager-plugin --version` again.
- Confirm this file exists: `C:\Program Files\Amazon\SessionManagerPlugin\bin\session-manager-plugin.exe`
- If needed, add `C:\Program Files\Amazon\SessionManagerPlugin\bin` to your PATH.

Official install guide:
- <https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html>

Then connect your SQL client to:
- Host: `localhost`
- Port: `5432`
- Database: `app` (or your configured `db_name`)
- Username/password: your Terraform `db_username` / `db_password`

This keeps the database private (`publicly_accessible = false`) and avoids placing DB resources in public subnets.

## Optional: scale backend down to zero

```powershell
terraform -chdir=infra/dev apply -auto-approve -var service_desired_count=0
```

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


