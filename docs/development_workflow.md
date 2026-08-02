# Development workflow

## Branches

- `main`: stable, reviewed work.
- `feature/warehouse-foundation`: repository and warehouse foundation.
- Future work should use focused branches such as:
  - `feature/bigquery-ingestion`
  - `feature/dbt-staging-models`
  - `feature/dbt-analytics-marts`
  - `feature/power-bi-dashboard`

## Commit convention

Use short Conventional Commit-style messages:

```text
feat: add dbt staging models
fix: correct crash date parsing
docs: document BigQuery ingestion flow
chore: update dbt dependencies
```

Each feature branch should contain one coherent change, be inspected locally and be merged into `main` only after validation.

## Current branch

The warehouse foundation is being developed on `feature/warehouse-foundation`. No remote push is performed automatically.
