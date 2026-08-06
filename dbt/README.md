# dbt project

This directory contains the dbt project for the Chicago Traffic Crashes
warehouse. The current implementation builds the staging view
`stg_traffic_crashes` in the `traffic_crashes_dev` dataset.

Start with the educational workflow in
[`docs/dbt_workflow.md`](../docs/dbt_workflow.md). The quick validation flow is:

```bash
cp dbt/profiles.yml.example dbt/profiles.yml
.venv/bin/dbt debug --project-dir dbt --profiles-dir dbt
.venv/bin/dbt parse --project-dir dbt --profiles-dir dbt
.venv/bin/dbt build --project-dir dbt --profiles-dir dbt --select stg_traffic_crashes
```

The local `dbt/profiles.yml` is ignored by Git. It contains connection settings,
not source code, and must not contain private keys or tokens.
