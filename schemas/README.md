# BigQuery schemas

This directory contains explicit BigQuery schemas used by the ingestion layer.

`traffic_crashes_raw.json` defines the expected columns and data types for the
raw Chicago traffic-crashes table. The schema is intentionally explicit instead
of relying on BigQuery autodetection. That makes the load reproducible and
prevents a changed value in a future CSV snapshot from silently changing a
column type.

The raw layer is not the cleaning layer. Dates that arrive as text remain text
in the raw table so that the source representation is preserved. Business
transformations and analytical types will be introduced later in dbt staging
models.
