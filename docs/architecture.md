# Analytics architecture

## Target flow

```text
Chicago Traffic Crashes CSV
          |
          v
Cloud Storage landing zone
          |
          v
BigQuery raw dataset
          |
          v
dbt staging models
          |
          v
dbt analytical marts
       /       \
      v         v
 Python      Power BI
 notebook    dashboard
```

## Layer responsibilities

### Raw layer

The raw table preserves the source structure as closely as possible. It is used for traceability and reloads, not for direct dashboard consumption.

### Staging layer

Staging models standardize data types, parse timestamps, normalize null values and expose consistent column names.

### Analytical marts

Marts contain reusable business-facing datasets such as one row per crash, daily summaries and risk-factor comparisons. Power BI should consume marts rather than repeat the cleaning logic.

### Python notebook

Python is used for exploratory analysis, statistical inference and later predictive modelling. It should consume the curated dataset or analytical extracts instead of defining a second, conflicting transformation pipeline.

### Power BI

Power BI is used for interactive reporting and decision-oriented communication. Measures and presentation logic belong there; source cleaning belongs upstream in dbt/BigQuery.

## Design principles

- Preserve the raw source.
- Transform once and reuse the result.
- Test important assumptions.
- Keep credentials outside the repository.
- Separate descriptive association from causal claims.
