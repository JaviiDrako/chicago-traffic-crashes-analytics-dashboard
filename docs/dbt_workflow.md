# dbt workflow

This document explains how dbt is used in this project, why each file exists,
how a dbt command becomes a BigQuery object, and how to troubleshoot the local
workflow.

## 1. What dbt does in this project

dbt is the transformation and testing layer between the raw BigQuery table and
the analytical datasets. It lets us write SQL transformations as versioned
models, declare dependencies, test assumptions, and generate documentation and
lineage.

dbt does not upload the CSV, replace the ingestion script, or act as the
dashboard. Those responsibilities are deliberately separated:

| Responsibility | Tool or layer |
|---|---|
| Store the source file | Cloud Storage |
| Load the source snapshot | bq load in scripts/load_raw_bigquery.sh |
| Preserve the source table | traffic_crashes_raw.raw_traffic_crashes |
| Clean, type, and document SQL models | dbt |
| Store development models | traffic_crashes_dev |
| Store reusable business marts | traffic_crashes_analytics |
| Explore statistics | Python notebook |
| Present business-facing metrics | Power BI |

The current branch implements both the typed staging layer and the Gold
analytics layer:

~~~text
Cloud Storage CSV
        |
        v
BigQuery raw table
        |
        | dbt source()
        v
stg_traffic_crashes view
        |
        | dbt ref() + tests
        v
Gold star schema and aggregate marts
        |
        v
traffic_crashes_analytics
~~~

The raw table is never modified by the staging model. A failed test is a signal
to investigate the source or transformation; it is not a reason to rewrite raw
data.

## 2. Project structure

~~~text
dbt/
├── dbt_project.yml
├── profiles.yml.example
├── profiles.yml                 # local only; ignored by Git
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── stg_traffic_crashes.sql
│   │   └── stg_traffic_crashes.yml
│   └── marts/
│       ├── marts.yml
│       ├── dim_date.sql
│       ├── dim_weather.sql
│       ├── dim_lighting.sql
│       ├── dim_severity.sql
│       ├── fct_traffic_crashes.sql
│       ├── mart_crashes_daily.sql
│       ├── mart_risk_factors.sql
│       └── mart_severity_summary.sql
├── tests/
│   ├── staging/
│   │   ├── assert_raw_traffic_crashes_binary_flags.sql
│   │   ├── assert_stg_traffic_crashes_coordinates.sql
│   │   └── assert_stg_traffic_crashes_temporal_ranges.sql
│   └── marts/
│       ├── assert_fct_traffic_crashes_measures.sql
│       ├── assert_mart_crashes_daily_reconciles.sql
│       ├── assert_mart_risk_factors_are_valid.sql
│       ├── assert_mart_risk_factors_grain.sql
│       └── assert_mart_severity_share_reconciles.sql
├── macros/
│   └── generate_schema_name.sql
├── seeds/
└── snapshots/
~~~

### dbt_project.yml

This is the project manifest. It defines the project name, profile name,
resource directories, and default materializations. The staging directory is
configured as a view, so dbt creates a logical query in BigQuery instead of
copying the full dataset into another physical table. The marts directory is
configured as physical tables in the explicitly named
`traffic_crashes_analytics` dataset.

The clean-targets section tells dbt clean which generated local folders can be
removed. These folders contain compiled SQL, logs, and artifacts; they are not
source code and are ignored by Git.

### profiles.yml

The profile contains environment-specific connection settings:

- project: GCP project where objects are created.
- dataset: default dataset for dbt models, traffic_crashes_dev.
- location: BigQuery location, US.
- threads: maximum number of parallel dbt tasks.
- priority: interactive, so development jobs run immediately.
- method: oauth, which uses local Google authentication rather than a service
  account key committed to the repository.

The committed profiles.yml.example is safe to share. The actual profiles.yml is
ignored because profiles are local configuration. A fresh clone can use either:

~~~bash
# Option A: keep the profile inside this repository, but ignored by Git.
cp dbt/profiles.yml.example dbt/profiles.yml

# Option B: use dbt's standard user-level profile location.
mkdir -p ~/.dbt
cp dbt/profiles.yml.example ~/.dbt/profiles.yml
~~~

The commands in this project explicitly pass --profiles-dir dbt, so Option A is
convenient for local reproducibility. No private key or access token should be
added to either file.

### Why a schema-name macro exists

dbt normally prefixes a custom schema with the target dataset. For example, a
custom schema named `analytics` could become
`traffic_crashes_dev_analytics`. This project already created named BigQuery
datasets for development and analytics, so
`macros/generate_schema_name.sql` preserves explicit custom dataset names:

- models without a custom schema use the profile dataset,
  `traffic_crashes_dev`.
- models under `models/marts` use the configured custom schema,
  `traffic_crashes_analytics`.

This keeps the environment boundary visible in BigQuery and makes the intended
warehouse architecture easy to inspect. In a larger multi-environment project,
the macro could be extended to map different targets to isolated datasets.

## 3. Authentication and connection checks

The BigQuery adapter needs permission to query the raw dataset, create the
staging view in the development dataset and create Gold tables in the analytics
dataset. The local OAuth/ADC setup is separate from the dbt project files:

~~~bash
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project traffic-crashes-warehouse
~~~

Run the diagnostic command from the repository root:

~~~bash
.venv/bin/dbt debug \
  --project-dir dbt \
  --profiles-dir dbt
~~~

dbt debug checks that dbt can find the project, resolve the traffic_crashes
profile, load the BigQuery adapter, and authenticate to the configured project.
It does not build a model.

The profile uses the same US location as the raw dataset. BigQuery jobs must use
compatible locations, so keeping raw and development datasets aligned avoids a
common failure.

## 4. Sources and lineage

The file models/staging/_sources.yml declares the raw BigQuery table as a dbt
source. A source is an object that exists outside dbt but is consumed by dbt.
It is different from a model because dbt does not create it.

The SQL model references it with:

~~~sql
from {{ source('traffic_crashes_raw', 'raw_traffic_crashes') }}
~~~

dbt renders this macro into a fully qualified BigQuery table reference. Using
source() instead of hard-coding a table name gives dbt lineage, source tests,
and a single place to change the source configuration.

The source declaration records the table grain: one row per CRASH_RECORD_ID. It
also applies not_null and unique tests to that key. Those tests repeat an
important ingestion assumption at the transformation boundary.

No source freshness rule is configured yet because the raw table does not have
an ingestion timestamp column. A future ingestion metadata field or separate
load-audit table can support freshness checks without changing business columns.

## 5. The staging model

models/staging/stg_traffic_crashes.sql has three conceptual responsibilities.

### Read the declared source

The source CTE reads the raw table through source(). It does not read the local
CSV and it does not duplicate the ingestion process.

### Standardize and type fields

The typed CTE applies row-level transformations:

- Renames uppercase source columns into consistent snake_case names.
- Uses TRIM and NULLIF so blank strings become SQL NULL.
- Parses CRASH_DATE and DATE_POLICE_NOTIFIED with
  SAFE.PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', ...).
- Converts numeric fields explicitly with SAFE_CAST.
- Converts source Y/N indicator fields into nullable booleans.
- Keeps local date-times as DATETIME because the source has no timezone
  information; it does not invent a UTC conversion.
- Converts the source LATITUDE = 0 and LONGITUDE = 0 pair into missing
  coordinates while preserving raw values in the raw layer.
- Keeps the original WKT location string as location_wkt for traceability.

SAFE_CAST and SAFE.PARSE_DATETIME return NULL instead of aborting the entire
query when a value cannot be converted. Tests and null profiles make those
conversion problems visible.

### Add reusable row-level fields

The enriched CTE adds fields useful to downstream consumers:

- crash_date, crash_year, crash_month_name, and crash_day_name.
- has_coordinates.
- is_injury_crash, based on injuries_total greater than zero.
- is_fatal_crash, based on injuries_fatal greater than zero.

These are row-level attributes. The model does not calculate daily totals,
percentages, or dashboard measures; those belong in later marts or Power BI.

### Preserve the grain

The staging model remains at one row per crash record. It does not join a
dimension or aggregate records, so the staging row count should match raw.

## 6. Gold dimensional model and analytics marts

The Gold layer is designed as a star schema. A star schema separates the
central event table (the fact) from descriptive lookup tables (the dimensions).
The fact keeps the measurable event grain; dimensions make filtering, grouping
and reuse easier for SQL and Power BI.

### Model grains and destinations

| Model | Grain | Materialization | BigQuery dataset | Main purpose |
|---|---|---|---|---|
| `dim_date` | One observed calendar date | Table | `traffic_crashes_analytics` | Calendar slicing and sorting |
| `dim_weather` | One normalized weather label | Table | `traffic_crashes_analytics` | Weather filters and grouped categories |
| `dim_lighting` | One normalized lighting label | Table | `traffic_crashes_analytics` | Lighting filters and grouped categories |
| `dim_severity` | One normalized severity label | Table | `traffic_crashes_analytics` | Severity ranking and flags |
| `fct_traffic_crashes` | One `crash_record_id` | Table | `traffic_crashes_analytics` | Central event facts, measures and keys |
| `mart_crashes_daily` | One crash date | Table | `traffic_crashes_analytics` | Daily time-series reporting |
| `mart_risk_factors` | One weather/lighting combination | Table | `traffic_crashes_analytics` | Environmental comparisons and rates |
| `mart_severity_summary` | One severity label | Table | `traffic_crashes_analytics` | Outcome distribution and shares |

The staging model is still a view in `traffic_crashes_dev`. The fact and
dimensions are tables because they form a reusable curated layer. The three
aggregate marts are also tables because they precompute common dashboard
queries and expose a simple grain to Power BI.

### Dimension construction

The dimensions are generated from distinct values observed in staging. Missing
categorical values are deliberately represented as `Unknown` instead of being
left without a foreign key. This makes the fact-to-dimension relationships
complete and makes missingness visible in reports.

`dim_date` uses a numeric `YYYYMMDD` key and calendar attributes such as year,
quarter, month, week, day name and weekend flag. The other dimensions use
BigQuery `FARM_FINGERPRINT` keys built from a namespace and normalized label,
for example `weather|Clear`. The namespace prevents the same label in two
different dimensions from producing the same intended key. These are
deterministic keys: the same source label receives the same key across a full
rebuild. For a production system with slowly changing reference data, a
managed key strategy could be introduced later.

### Fact construction

`fct_traffic_crashes.sql` reads staging at its declared grain and left joins
each dimension to attach foreign keys. It keeps row-level attributes that are
useful for analysis, converts missing injury measures to zero, and adds
`crash_count = 1`. The constant measure makes safe additive aggregation
explicit: `SUM(crash_count)` is the number of crash records at any grouping.

The fact does not aggregate rows. That is important because a later mart can be
rebuilt at a different grain without losing the source event detail.

### Aggregate marts

`mart_crashes_daily` joins the fact to the date dimension and calculates crash
volume, injury counts, fatal-crash counts and supporting averages for each date.
`mart_risk_factors` combines weather and lighting dimensions and calculates
crash counts, injury/fatal rates and injury totals. Rates are calculated with
`SAFE_DIVIDE` so a zero denominator cannot fail a query. `mart_severity_summary`
groups the fact by the severity dimension and calculates the share of all
crashes represented by each outcome category.

These marts are not replacements for the fact. They are purpose-built serving
tables for recurring questions and dashboard performance. Power BI can still
use the star schema directly when users need flexible slicing.

### Why `ref()` matters here

Every model references upstream models with `ref()`, not hard-coded table names.
dbt uses those references to build a dependency graph and execute models in the
right order: staging, dimensions, fact and finally aggregate marts. The same
references also produce lineage in dbt documentation and make schema changes
easier to review.

## 7. Tests and their meaning

dbt tests are SQL assertions. A test passes when its query returns zero rows.
Tests do not repair data; they verify that assumptions still hold.

### Generic tests in YAML

The staging schema file applies built-in tests such as:

- not_null and unique for crash_record_id.
- not_null for parsed crash_datetime and crash_date.
- accepted_values for month, weekday, and hour ranges.
- accepted_values for normalized boolean fields.
- not_null and unique tests for dimension keys and natural labels.
- relationships tests for fact foreign keys.
- grain tests for daily, risk-factor and severity marts.

Generic tests are reusable configurations attached to columns. dbt generates
the SQL for them.

### Singular tests in dbt/tests

The repository also contains purpose-built SQL tests:

- assert_raw_traffic_crashes_binary_flags.sql checks that raw indicator
  columns contain only Y, N, or blank values.
- assert_stg_traffic_crashes_temporal_ranges.sql checks hour, weekday, and
  month domains in the staging model.
- assert_stg_traffic_crashes_coordinates.sql checks that non-null coordinates
  remain inside a broad Chicago-area bounding box.
- assert_fct_traffic_crashes_measures.sql checks non-negative injury measures,
  measure ordering and the one-row-per-crash count measure.
- assert_mart_crashes_daily_reconciles.sql checks that the daily rollup equals
  the total fact count.
- assert_mart_risk_factors_are_valid.sql checks that rates remain between zero
  and one.
- assert_mart_risk_factors_grain.sql checks one row per weather/lighting pair.
- assert_mart_severity_share_reconciles.sql checks that severity shares sum to
  one.

Singular tests are useful when a source or business rule is clearer as a
standalone query than as generic configuration.

## 8. Local dbt workflow

Run commands from the repository root. Explicit project and profile paths avoid
ambiguity when the repository contains notebooks and dbt.

### Parse the project

~~~bash
.venv/bin/dbt parse \
  --project-dir dbt \
  --profiles-dir dbt
~~~

parse validates YAML, Jinja, project structure, and the dependency graph. It
does not create the staging view.

### Inspect resources

~~~bash
.venv/bin/dbt ls \
  --project-dir dbt \
  --profiles-dir dbt
~~~

This lists models, sources, tests, and other resources known to dbt.

### Compile SQL

~~~bash
.venv/bin/dbt compile \
  --project-dir dbt \
  --profiles-dir dbt \
  --select path:models/marts
~~~

compile renders Jinja macros such as source() and writes the resulting SQL
under dbt/target/compiled. It helps inspect the SQL sent to BigQuery. Some
BigQuery adapter operations may still require authentication.

### Build the staging model and its tests

~~~bash
.venv/bin/dbt build \
  --project-dir dbt \
  --profiles-dir dbt \
  --select stg_traffic_crashes
~~~

build is the normal CI-style command for this branch. It runs the selected model
and its associated tests in dependency order. A successful build creates or
replaces this view:

~~~text
traffic-crashes-warehouse.traffic_crashes_dev.stg_traffic_crashes
~~~

The view is created in traffic_crashes_dev because that is the development
dataset configured by the profile.

### Build the Gold layer and its tests

~~~bash
.venv/bin/dbt build \
  --project-dir dbt \
  --profiles-dir dbt \
  --select path:models/marts
~~~

This selector builds every model under `models/marts` and the tests attached to
those models. dbt follows `ref()` dependencies, so the dimensions and fact are
built before the aggregate marts. The resulting objects are:

~~~text
traffic-crashes-warehouse.traffic_crashes_analytics.dim_date
traffic-crashes-warehouse.traffic_crashes_analytics.dim_weather
traffic-crashes-warehouse.traffic_crashes_analytics.dim_lighting
traffic-crashes-warehouse.traffic_crashes_analytics.dim_severity
traffic-crashes-warehouse.traffic_crashes_analytics.fct_traffic_crashes
traffic-crashes-warehouse.traffic_crashes_analytics.mart_crashes_daily
traffic-crashes-warehouse.traffic_crashes_analytics.mart_risk_factors
traffic-crashes-warehouse.traffic_crashes_analytics.mart_severity_summary
~~~

To rebuild one serving mart together with all upstream dependencies, use
`--select +mart_crashes_daily`, or replace that name with another downstream
mart. The leading `+` tells dbt to include parents in the dependency graph.

### Run source tests explicitly

~~~bash
.venv/bin/dbt test \
  --project-dir dbt \
  --profiles-dir dbt \
  --select source:traffic_crashes_raw
~~~

This checks the raw source key independently from the staging model.

### Generate project documentation

~~~bash
.venv/bin/dbt docs generate \
  --project-dir dbt \
  --profiles-dir dbt

.venv/bin/dbt docs serve \
  --project-dir dbt \
  --profiles-dir dbt
~~~

docs generate creates the catalog and manifest used by the documentation site.
docs serve starts a local web server where model descriptions, column metadata,
and the lineage graph can be inspected.

### Clean generated artifacts

~~~bash
.venv/bin/dbt clean --project-dir dbt --profiles-dir dbt
~~~

This removes only generated directories listed in clean-targets. It does not
delete BigQuery tables or views.

## 9. Recommended development sequence

For a change to the staging or Gold layer:

1. Confirm that the raw table and ingestion validation are available.
2. Edit the SQL model and its YAML documentation together.
3. Run dbt parse to catch configuration problems early.
4. Run dbt compile and inspect rendered SQL when the transformation is
   non-trivial.
5. Run the narrowest relevant build: staging for staging changes, or
   `--select path:models/marts` for the Gold layer.
6. Review row count, grain, schema, nulls, relationships and test results in
   BigQuery.
7. Generate documentation if model descriptions or lineage changed.
8. Commit SQL, YAML, and documentation together.

The raw table is the audit boundary. Staging is the type and naming boundary.
The fact and dimensions are the reusable business-model boundary. Aggregate
marts are the serving boundary for recurring dashboard questions.

## 10. Troubleshooting

### Could not find profile named traffic_crashes

The profile value in dbt/dbt_project.yml must match the top-level key in
profiles.yml. Use --profiles-dir dbt if the local profile is inside the
repository, or --profiles-dir ~/.dbt if it is stored in the standard location.

### Access denied or OAuth errors

Run gcloud auth application-default login, confirm the active project, and run
dbt debug. The local user needs permission to query the raw dataset and create
views in the development dataset and tables in the analytics dataset.

### Dataset or location errors

Check that the profile uses `traffic_crashes_dev` and `US`, that the source
declaration points to `traffic_crashes_raw`, and that the BigQuery analytics
dataset `traffic_crashes_analytics` exists in the same project and location.

### A test fails

Read the failing test name and inspect the returned rows. Do not disable the
test automatically. Decide whether the issue is source quality, an incorrect
transformation, or an assumption that needs documentation.

### The source table cannot be found

Run the raw-ingestion validation first. dbt expects the table
traffic_crashes_raw.raw_traffic_crashes to already exist; dbt does not create
it from the CSV.

## 11. Portfolio value

This dbt layer demonstrates:

- Separation between ingestion, raw storage, and transformation layers.
- Reusable source declarations and model lineage.
- Explicit typing and safe parsing of semi-structured CSV values.
- Reusable data-quality tests.
- A documented star schema with explicit grains and foreign-key relationships.
- Physical serving marts designed for BI consumption.
- Documentation as part of the data model.
- A workflow that can later be orchestrated by CI/CD or Airflow.
