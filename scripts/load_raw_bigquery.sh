#!/usr/bin/env bash

# Load the unchanged CSV snapshot from Cloud Storage into the BigQuery raw layer.
# Usage: bash scripts/load_raw_bigquery.sh [path/to/.env]

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
: "${GCS_BUCKET_NAME:?GCS_BUCKET_NAME is required}"
: "${GCS_OBJECT_PATH:?GCS_OBJECT_PATH is required}"
: "${RAW_DATASET:?RAW_DATASET is required}"
: "${RAW_TABLE:?RAW_TABLE is required}"
: "${SCHEMA_FILE:?SCHEMA_FILE is required}"

if ! command -v bq >/dev/null 2>&1; then
  echo "The BigQuery CLI (bq) is not available in PATH." >&2
  exit 1
fi

SCHEMA_PATH="${SCHEMA_FILE}"
if [[ "${SCHEMA_PATH}" != /* ]]; then
  SCHEMA_PATH="${REPO_ROOT}/${SCHEMA_PATH}"
fi

if [[ ! -f "${SCHEMA_PATH}" ]]; then
  echo "Schema file not found: ${SCHEMA_PATH}" >&2
  exit 1
fi

RAW_TABLE_ID="${GCP_PROJECT_ID}:${RAW_DATASET}.${RAW_TABLE}"
GCS_URI="gs://${GCS_BUCKET_NAME}/${GCS_OBJECT_PATH}"

echo "Loading ${GCS_URI} into ${RAW_TABLE_ID}"
echo "Using explicit schema: ${SCHEMA_PATH}"
echo "A successful load replaces the same raw table so reruns are reproducible."

bq --location="${GCP_LOCATION}" load \
  --replace \
  --source_format=CSV \
  --encoding=UTF-8 \
  --field_delimiter="," \
  --skip_leading_rows=1 \
  --max_bad_records=0 \
  "${RAW_TABLE_ID}" \
  "${GCS_URI}" \
  "${SCHEMA_PATH}"

echo "Raw table loaded. Running validation queries..."
bash "${SCRIPT_DIR}/validate_raw_bigquery.sh" "${ENV_FILE}"
