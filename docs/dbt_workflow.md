# dbt workflow

## Purpose

dbt will manage SQL transformations inside BigQuery. It will provide model dependencies, tests, documentation and lineage while keeping transformations reviewable in Git.

## Planned models

```text
source: raw_traffic_crashes
        |
        v
stg_traffic_crashes
        |
        +--> fct_traffic_crashes
        +--> mart_crashes_daily
        +--> mart_risk_factors
        +--> mart_severity_summary
```

## Initial tests

- Crash record ID is not null.
- Crash record ID is unique.
- Crash hour is between 0 and 23.
- Crash day of week is between 1 and 7.
- Crash month is between 1 and 12.
- Derived flags contain only boolean values.

## Local configuration

Install the BigQuery adapter in an isolated environment:

```bash
python -m pip install dbt-core dbt-bigquery
```

Copy `dbt/profiles.yml.example` to the standard local dbt profiles directory and replace placeholders locally. The real `profiles.yml` is ignored by Git.

The first commands after configuration will be:

```bash
dbt debug
dbt parse
dbt build
```
