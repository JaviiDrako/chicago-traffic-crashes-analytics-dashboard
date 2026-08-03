# SQL workspace

Standalone BigQuery SQL files can be stored here when they are useful outside
the dbt project, such as source profiling and ingestion validation queries.

The `validation/` queries are intentionally read-only. They inspect the raw
table after a load and do not clean, update or delete records. The shell
validation script replaces the placeholders in these files with the project,
dataset and table configured in `.env`, then sends the rendered Standard SQL to
BigQuery through `bq query`.

Production transformations should live in `dbt/models/` so that they are tested
and documented.
