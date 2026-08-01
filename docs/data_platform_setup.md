# Data platform setup

This document describes the setup required before connecting the project to BigQuery.

## User-owned setup

The project owner must create or select a Google Cloud project, enable billing according to their account terms, and choose a BigQuery/Cloud Storage location. The project owner also controls authentication and permissions.

Required future values:

- GCP project ID
- Cloud Storage bucket name
- BigQuery location
- BigQuery raw dataset name
- BigQuery analytics dataset name

Do not share passwords, OAuth refresh tokens or service-account JSON keys in chat or Git.

## Planned ingestion

1. Keep the source CSV unchanged in a local or Cloud Storage landing zone.
2. Load the file into a BigQuery raw table with an explicit schema where practical.
3. Validate row counts, columns, nulls, date parsing and key uniqueness.
4. Transform the raw table with dbt models.
5. Expose curated marts to the notebook and Power BI.

The CSV will not be committed to Git because it is a large raw asset.
