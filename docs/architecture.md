# Analytics architecture

## Current and target flow

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

The project, Cloud Storage landing zone, BigQuery datasets, raw BigQuery table
and dbt models are now configured. The raw load contains 1,079,880 rows across
49 columns, and the ingestion validation checks passed. The dbt staging view
preserves the same row grain and exposes 56 typed/derived columns. The Gold
layer now adds four dimensions, a one-row-per-crash fact table and three
Power BI-oriented aggregate marts in `traffic_crashes_analytics`.
The complete dbt build currently passes 9 models and 80 data tests.

## Layer responsibilities

### Raw layer

The raw table preserves the source structure as closely as possible. It is used for traceability and reloads, not for direct dashboard consumption.

The current raw file is stored at:

```text
gs://traffic-crashes-warehouse-raw/raw/Chicago_Traffic_Crashes.csv
```

### Staging layer

The current `stg_traffic_crashes` view standardizes data types, parses local
date-times, normalizes null values, converts source flags to booleans, handles
the source `0,0` coordinate placeholder and exposes consistent column names.
It remains at one row per crash record and is materialized in
`traffic_crashes_dev`.

### Analytical marts

Marts contain reusable business-facing datasets such as one row per crash, daily summaries and risk-factor comparisons. Power BI should consume marts rather than repeat the cleaning logic.

The implemented dimensional model uses `fct_traffic_crashes` at one-row-per-
crash grain, supported by `dim_date`, `dim_weather`, `dim_lighting` and
`dim_severity`. The fact table stores measures, flags and foreign keys; the
dimensions store reusable descriptive attributes. This is a star schema: the
fact is the center and the dimensions are the surrounding filter and grouping
tables.

The layer also contains three purpose-built aggregate marts:

- `mart_crashes_daily` for time-series volume and injury trends.
- `mart_risk_factors` for weather/lighting comparisons and rates.
- `mart_severity_summary` for outcome distribution and severity shares.

The marts are physical BigQuery tables rather than views so Power BI can query
small, stable, reusable datasets without repeating joins and aggregations. A
custom dbt schema-name macro keeps these models in the exact
`traffic_crashes_analytics` dataset while staging remains in
`traffic_crashes_dev`.

### Python notebook

Python is used for exploratory analysis, statistical inference and later
predictive modelling. The notebook now consumes a narrow query over the Gold
fact table joined to the weather, lighting and severity dimensions. It performs
lightweight contract checks and analysis-specific feature engineering instead
of defining a second raw-data cleaning pipeline.

### Power BI

Power BI is used for interactive reporting and decision-oriented communication. Measures and presentation logic belong there; source cleaning belongs upstream in dbt/BigQuery.

## Design principles

- Preserve the raw source.
- Transform once and reuse the result.
- Test important assumptions.
- Keep credentials outside the repository.
- Make the grain and ownership of every model explicit.
- Separate descriptive association from causal claims.
