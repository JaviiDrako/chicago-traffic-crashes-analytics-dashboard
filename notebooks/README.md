# Notebooks

Notebook files are organized by analytical purpose. The current notebook contains
the original statistical analysis plus the Phase 1 and Phase 2 extensions.

The main notebook now reads a narrow analytical extract from the BigQuery Gold
layer: `fct_traffic_crashes` joined to the weather, lighting and severity
dimensions. Structural cleaning and typing are owned by dbt; the notebook keeps
only lightweight contract checks and analysis-specific feature engineering.

Before running locally, authenticate with Google Application Default
Credentials:

```bash
gcloud auth application-default login
```

Install `requirements.txt`, select the project virtual environment as the
notebook kernel, and run the cells from top to bottom. The CSV is no longer the
primary notebook source.
