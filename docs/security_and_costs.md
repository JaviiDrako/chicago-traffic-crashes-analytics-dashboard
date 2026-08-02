# Security and cost controls

## Credentials

Never commit or share:

- service-account JSON files;
- OAuth refresh tokens;
- access tokens;
- passwords;
- files from local credential directories.

The repository ignores `dbt/profiles.yml`, but the real profile should live in the standard local dbt configuration directory whenever possible. The committed `dbt/profiles.yml.example` contains placeholders only.

## Local authentication

For development, Application Default Credentials are more appropriate than placing a service-account key in the repository:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project traffic-crashes-warehouse
```

For a future automated job, use a dedicated service account with the smallest set of permissions required. Do not reuse a personal account for unattended production workloads.

## Cost awareness

The project currently has a promotional Google Cloud credit. It is still important to treat every query as a potentially billable operation.

Initial controls:

- Create a budget alert in **Billing → Budgets & alerts**.
- Prefer load jobs for the raw CSV instead of repeatedly reading external files.
- Select only required columns in analytical queries.
- Avoid `SELECT *` in dashboard queries.
- Partition time-based analytical tables by date when appropriate.
- Cluster tables by frequently filtered fields when the table design justifies it.
- Use dry runs or estimated bytes processed before expensive queries.
- Delete temporary development tables when they are no longer needed.
- Keep raw and curated datasets separate so access and retention can be managed independently.

A budget alert notifies you; it does not automatically guarantee that all spending will stop. Review billing settings and current Google Cloud pricing before moving beyond small development workloads.

## Data access boundaries

- Raw data should be writable by ingestion processes and readable only by users who need source-level access.
- dbt needs permission to read raw sources and create development/analytics models.
- Power BI should read curated analytics tables rather than raw data.
- The notebook should query only the curated columns needed for analysis.

## Repository safety

The 648 MB CSV is excluded from Git. The repository stores schemas, SQL, dbt configuration examples and documentation, not large raw assets or credentials.
