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

The current branch implements the first dbt layer:

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
        | dbt tests
        v
traffic_crashes_dev
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
│   └── staging/
│       ├── _sources.yml
│       ├── stg_traffic_crashes.sql
│       └── stg_traffic_crashes.yml
├── tests/
│   └── staging/
│       ├── assert_raw_traffic_crashes_binary_flags.sql
│       ├── assert_stg_traffic_crashes_coordinates.sql
│       └── assert_stg_traffic_crashes_temporal_ranges.sql
├── macros/
├── seeds/
└── snapshots/
~~~

### dbt_project.yml

This is the project manifest. It defines the project name, profile name,
resource directories, and default materializations. The staging directory is
configured as a view, so dbt creates a logical query in BigQuery instead of
copying the full dataset into another physical table.

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

## 3. Authentication and connection checks

The BigQuery adapter needs permission to query the raw dataset and create views
in the development dataset. The local OAuth/ADC setup is separate from the dbt
project files:

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

## 6. Tests and their meaning

dbt tests are SQL assertions. A test passes when its query returns zero rows.
Tests do not repair data; they verify that assumptions still hold.

### Generic tests in YAML

The staging schema file applies built-in tests such as:

- not_null and unique for crash_record_id.
- not_null for parsed crash_datetime and crash_date.
- accepted_values for month, weekday, and hour ranges.
- accepted_values for normalized boolean fields.

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

Singular tests are useful when a source or business rule is clearer as a
standalone query than as generic configuration.

## 7. Local dbt workflow

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
  --select stg_traffic_crashes
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

## 8. Recommended development sequence

For a change to the staging layer:

1. Confirm that the raw table and ingestion validation are available.
2. Edit the SQL model and its YAML documentation together.
3. Run dbt parse to catch configuration problems early.
4. Run dbt compile and inspect rendered SQL when the transformation is
   non-trivial.
5. Run dbt build --select stg_traffic_crashes against the development dataset.
6. Review row count, schema, nulls, and test results in BigQuery.
7. Generate documentation if model descriptions or lineage changed.
8. Commit SQL, YAML, and documentation together.

The raw table is the audit boundary. Staging is the type and naming boundary.
The future marts branch will be the business metric and dimensional-model
boundary.

## 9. Troubleshooting

### Could not find profile named traffic_crashes

The profile value in dbt/dbt_project.yml must match the top-level key in
profiles.yml. Use --profiles-dir dbt if the local profile is inside the
repository, or --profiles-dir ~/.dbt if it is stored in the standard location.

### Access denied or OAuth errors

Run gcloud auth application-default login, confirm the active project, and run
dbt debug. The local user needs permission to query the raw dataset and create
views in the development dataset.

### Dataset or location errors

Check that the profile uses traffic_crashes_dev and US, and that the source
declaration points to traffic_crashes_raw in the same project.

### A test fails

Read the failing test name and inspect the returned rows. Do not disable the
test automatically. Decide whether the issue is source quality, an incorrect
transformation, or an assumption that needs documentation.

### The source table cannot be found

Run the raw-ingestion validation first. dbt expects the table
traffic_crashes_raw.raw_traffic_crashes to already exist; dbt does not create
it from the CSV.

## 10. Portfolio value

This dbt layer demonstrates:

- Separation between ingestion, raw storage, and transformation layers.
- Reusable source declarations and model lineage.
- Explicit typing and safe parsing of semi-structured CSV values.
- Reusable data-quality tests.
- Documentation as part of the data model.
- A workflow that can later be orchestrated by CI/CD or Airflow.
