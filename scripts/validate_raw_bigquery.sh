#!/usr/bin/env bash

# Run non-mutating validation queries against the BigQuery raw table.
# Usage: bash scripts/validate_raw_bigquery.sh [path/to/.env]

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${REPO_ROOT}/.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  echo "Create it with: cp .env.example .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${GCP_PROJECT_ID:?GCP_PROJECT_ID is required}"
: "${GCP_LOCATION:?GCP_LOCATION is required}"
: "${RAW_DATASET:?RAW_DATASET is required}"
: "${RAW_TABLE:?RAW_TABLE is required}"
: "${EXPECTED_ROW_COUNT:?EXPECTED_ROW_COUNT is required}"

if ! command -v bq >/dev/null 2>&1; then
  echo "The BigQuery CLI (bq) is not available in PATH." >&2
  exit 1
fi

RAW_SQL_TABLE_ID="${GCP_PROJECT_ID}.${RAW_DATASET}.${RAW_TABLE}"

run_sql_file() {
  local sql_file="$1"
  local rendered_sql

  if [[ ! -f "${sql_file}" ]]; then
    echo "SQL file not found: ${sql_file}" >&2
    exit 1
  fi

  rendered_sql="$(sed \
    -e "s|__RAW_SQL_TABLE_ID__|${RAW_SQL_TABLE_ID}|g" \
    -e "s|__PROJECT_ID__|${GCP_PROJECT_ID}|g" \
    -e "s|__RAW_DATASET__|${RAW_DATASET}|g" \
    -e "s|__RAW_TABLE__|${RAW_TABLE}|g" \
    -e "s|__EXPECTED_ROW_COUNT__|${EXPECTED_ROW_COUNT}|g" \
    "${sql_file}")"

  echo
  echo "Running ${sql_file}"
  # Send the query through stdin so a leading SQL comment is not interpreted
  # as a bq CLI flag.
  printf '%s\n' "${rendered_sql}" | \
    bq --location="${GCP_LOCATION}" query \
      --use_legacy_sql=false
}

run_sql_file "${REPO_ROOT}/sql/validation/raw_ingestion_summary.sql"
run_sql_file "${REPO_ROOT}/sql/validation/raw_schema_check.sql"
run_sql_file "${REPO_ROOT}/sql/validation/raw_null_profile.sql"

echo
echo "Raw-layer validation queries completed."
