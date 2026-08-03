# Scripts workspace

Repeatable local utilities belong here. Scripts must never contain credentials
or hard-code personal access tokens.

## BigQuery raw ingestion

Create a local environment file from the committed template:

```bash
cp .env.example .env
```

Review `.env` before running the scripts. It contains project, bucket, dataset,
table and snapshot settings, but no credentials. The file is ignored by Git.

Load the CSV from Cloud Storage into the raw BigQuery table:

```bash
bash scripts/load_raw_bigquery.sh
```

The loader uses the explicit schema in
`schemas/traffic_crashes_raw.json`, skips the CSV header and allows zero bad
records. The `--replace` option makes reruns deterministic by replacing the
same raw table. The source values are not cleaned or renamed in this step.

The loader automatically runs the validation script after a successful load.
To run only the non-mutating checks against an existing table:

```bash
bash scripts/validate_raw_bigquery.sh
```

The validation script sends the SQL files in `sql/validation/` to BigQuery. The
shell script only renders environment-specific identifiers; BigQuery executes
the SQL. The checks cover row-count fidelity, duplicate or missing record IDs,
basic date/time and coordinate ranges, zero-coordinate placeholders, the loaded
schema, and null profiles for important analytical fields.

Both scripts accept an alternative environment file as their first argument:

```bash
bash scripts/load_raw_bigquery.sh path/to/.env
bash scripts/validate_raw_bigquery.sh path/to/.env
```
