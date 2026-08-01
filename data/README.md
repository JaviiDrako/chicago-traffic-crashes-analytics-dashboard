# Data directory

Raw data files belong in `data/raw/` during local development and are excluded from Git because of their size.

The current source is the City of Chicago Traffic Crashes dataset. The intended cloud workflow is:

1. Keep an unchanged local/source snapshot.
2. Upload the snapshot to a controlled Cloud Storage landing zone.
3. Load it into a BigQuery raw table.
4. Apply cleaning and feature engineering in dbt.

Do not commit credentials, service-account keys or large CSV files to this repository.
