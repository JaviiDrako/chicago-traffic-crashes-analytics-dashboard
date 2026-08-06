# dbt project

This directory contains the dbt project for the Chicago Traffic Crashes
warehouse. The project builds the typed staging view
`stg_traffic_crashes` in `traffic_crashes_dev` and a Gold star schema plus
serving marts in `traffic_crashes_analytics`.

Start with the educational workflow in
[`docs/dbt_workflow.md`](../docs/dbt_workflow.md). The quick validation flow is:

```bash
cp dbt/profiles.yml.example dbt/profiles.yml
.venv/bin/dbt debug --project-dir dbt --profiles-dir dbt
.venv/bin/dbt parse --project-dir dbt --profiles-dir dbt
.venv/bin/dbt build --project-dir dbt --profiles-dir dbt --select stg_traffic_crashes
.venv/bin/dbt build --project-dir dbt --profiles-dir dbt --select path:models/marts
```

The local `dbt/profiles.yml` is ignored by Git. It contains connection settings,
not source code, and must not contain private keys or tokens. The latest full
build creates 9 models and passes 80 data tests.
