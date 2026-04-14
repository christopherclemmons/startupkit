#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}"

PROJECT_NAME="${1:-app}"
ENVIRONMENT="${2:-dev}"
AWS_REGION="${3:-us-east-2}"

DB_SUBNET_GROUP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-postgres-subnets"
DB_INSTANCE_IDENTIFIER="${PROJECT_NAME}-${ENVIRONMENT}-postgres"
OAC_NAME="${PROJECT_NAME}-${ENVIRONMENT}-oac"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

in_state() {
  terraform -chdir="${TF_DIR}" state show "$1" >/dev/null 2>&1
}

import_if_missing() {
  local address="$1"
  local import_id="$2"

  if in_state "${address}"; then
    echo "State already contains ${address}; skipping."
    return
  fi

  echo "Importing ${address} with id ${import_id}..."
  terraform -chdir="${TF_DIR}" import "${address}" "${import_id}"
}

require_cmd terraform
require_cmd aws

ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text)"
if [[ -z "${ACCOUNT_ID}" || "${ACCOUNT_ID}" == "None" ]]; then
  echo "Unable to resolve AWS account ID from current AWS credentials." >&2
  exit 1
fi

SITE_BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-${ACCOUNT_ID}-${AWS_REGION}-frontend-site"

echo "Recovering Terraform state for ${PROJECT_NAME}/${ENVIRONMENT} in ${AWS_REGION}..."

import_if_missing "module.rds_postgres.aws_db_subnet_group.this" "${DB_SUBNET_GROUP_NAME}"
import_if_missing "module.frontend_hosting.aws_s3_bucket.site" "${SITE_BUCKET_NAME}"

OAC_ID="$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='${OAC_NAME}'].Id | [0]" --output text)"
if [[ -z "${OAC_ID}" || "${OAC_ID}" == "None" || "${OAC_ID}" == "null" ]]; then
  echo "Could not find CloudFront OAC named ${OAC_NAME}." >&2
  exit 1
fi
import_if_missing "module.frontend_hosting.aws_cloudfront_origin_access_control.site" "${OAC_ID}"

DB_INSTANCE_EXISTS="$(
  aws rds describe-db-instances \
    --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
    --query 'DBInstances[0].DBInstanceIdentifier' \
    --output text 2>/dev/null || true
)"
if [[ "${DB_INSTANCE_EXISTS}" == "${DB_INSTANCE_IDENTIFIER}" ]]; then
  import_if_missing "module.rds_postgres.aws_db_instance.this" "${DB_INSTANCE_IDENTIFIER}"
fi

DISTRIBUTION_ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='${PROJECT_NAME}-${ENVIRONMENT} frontend'].Id | [0]" --output text)"
if [[ -n "${DISTRIBUTION_ID}" && "${DISTRIBUTION_ID}" != "None" && "${DISTRIBUTION_ID}" != "null" ]]; then
  import_if_missing "module.frontend_hosting.aws_cloudfront_distribution.site" "${DISTRIBUTION_ID}"
fi

echo
echo "State recovery complete."
echo "Next step:"
echo "terraform -chdir=infra/dev plan"


