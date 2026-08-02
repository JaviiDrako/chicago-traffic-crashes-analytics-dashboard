# Chicago Traffic Crashes Analytics

An end-to-end analytics project based on the City of Chicago Traffic Crashes dataset.

The project starts as a statistical analysis in Python and is being extended into a small analytics platform using BigQuery, dbt and Power BI.

## Project layers

```text
CSV source → Cloud Storage → BigQuery raw → dbt staging/marts → Python + Power BI
```

- **Python notebook:** descriptive statistics, probability and statistical inference.
- **BigQuery:** cloud warehouse for the raw and curated data.
- **dbt:** SQL transformations, data tests, documentation and lineage.
- **Power BI:** executive-facing dashboard and visual reporting.

## Repository structure

```text
data/       Local data landing-zone documentation
dbt/        dbt project, models, tests and configuration examples
docs/       Architecture and setup documentation
notebooks/  Exploratory and statistical analysis notebooks
scripts/    Repeatable local utilities and ingestion helpers
sql/        Standalone BigQuery SQL
```

The source CSV is intentionally excluded from Git because it is a large raw asset. See [`docs/data_platform_setup.md`](docs/data_platform_setup.md) for the planned ingestion workflow.

## Current status

- Original descriptive and probabilistic analysis completed.
- Phase 1: data quality, derived variables and comparative risk metrics completed.
- Phase 2: chi-square tests, Cramér's V and confidence intervals completed.
- Warehouse foundation: repository structure and documentation initialized.

## Local notebook

Install the analytical dependencies with:

```bash
pip install -r requirements.txt
```

Then select the project virtual environment as the notebook kernel and run [`notebooks/chicago_traffic_crashes_analysis.ipynb`](notebooks/chicago_traffic_crashes_analysis.ipynb).
