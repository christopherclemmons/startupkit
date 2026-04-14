# Infra Dev Helpers

## `import_orphaned_resources.sh`

Script path:
- `infra/dev/import_orphaned_resources.sh`

Purpose:
- Recover Terraform state after a failed or incomplete destroy/apply where AWS resources still exist but Terraform state does not track them.
- Prevent repeated `AlreadyExists` errors on dev infrastructure.

What it imports (if missing from state):
- `module.rds_postgres.aws_db_subnet_group.this`
- `module.frontend_hosting.aws_s3_bucket.site`
- `module.frontend_hosting.aws_cloudfront_origin_access_control.site`
- `module.rds_postgres.aws_db_instance.this` (only if the DB instance still exists)
- `module.frontend_hosting.aws_cloudfront_distribution.site` (only if the distribution still exists)

### Prerequisites

- AWS CLI installed and authenticated to the target account
- Terraform installed
- Run from repo root (recommended)
- `terraform -chdir=infra/dev init` has been run at least once

### Usage

```bash
chmod +x infra/dev/import_orphaned_resources.sh
./infra/dev/import_orphaned_resources.sh [project_name] [environment] [aws_region]
```

Arguments (all optional):
- `project_name` default: `app`
- `environment` default: `dev`
- `aws_region` default: `us-east-2`

Example:

```bash
./infra/dev/import_orphaned_resources.sh app dev us-east-2
terraform -chdir=infra/dev plan
```

Notes:
- Safe to rerun; resources already in state are skipped.
- If the script cannot find AWS account identity or required resources, it exits with an error so you can fix credentials or naming before continuing.


