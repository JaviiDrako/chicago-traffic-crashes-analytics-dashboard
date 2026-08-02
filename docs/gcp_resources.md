# GCP resource inventory

This is the non-secret inventory of resources created for the project. It is safe to keep resource names in Git; credentials and tokens must never be stored here.

## Project

```text
Project ID: traffic-crashes-warehouse
Project name: Traffic Crashes Warehouse
Status: ACTIVE
```

## Cloud Storage

```text
Bucket: gs://traffic-crashes-warehouse-raw
Object: raw/Chicago_Traffic_Crashes.csv
```

The object is the unchanged source snapshot. Cloud Storage is being used as the landing zone before a controlled BigQuery load.

## BigQuery datasets

| Dataset | Role | Expected contents |
|---|---|---|
| `traffic_crashes_raw` | Raw layer | Source table loaded from the CSV |
| `traffic_crashes_dev` | Development | dbt staging and intermediate models while developing |
| `traffic_crashes_analytics` | Curated layer | Facts, dimensions and Power BI-ready marts |

## Current status

- Project: created and active.
- APIs: enabled for the initial setup.
- Cloud Storage bucket: created.
- Source CSV: uploaded.
- BigQuery datasets: created.
- Raw BigQuery table: pending.
- dbt models and tests: pending.
- Power BI connection: pending.

## Location note

The Cloud Storage bucket and BigQuery datasets must use compatible locations. Record the actual location selected in the Google Cloud Console before creating the raw table. Dataset locations cannot be changed after creation.
