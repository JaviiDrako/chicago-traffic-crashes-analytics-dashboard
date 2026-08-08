# Business Intelligence

`bi/` is the Business Intelligence and analytics-consumption layer of the
Chicago Traffic Crashes project. It contains report artifacts that consume the
curated BigQuery Gold layer without duplicating ingestion or transformation
logic.

## Current implementation

The repository currently includes one BI implementation:

- [Power BI dashboard documentation](<Traffic Crashes Dashboard/README.md>)
- [Power BI project](<Traffic Crashes Dashboard/Traffic Crashes Dashboard.pbip>)

The report is delivered as a PBIP project so its report definition, semantic
model, pages, visuals, measures, relationships, theme, and registered image
resources can be reviewed and versioned as source files.

## Data consumption layer

The dashboard consumes the `traffic_crashes_analytics` dataset in the
`traffic-crashes-warehouse` BigQuery project. The current semantic model uses
the Gold fact table and conformed dimensions:

- `fct_traffic_crashes`
- `dim_date`
- `dim_weather`
- `dim_lighting`
- `dim_severity`

The report uses Power BI Import mode, explicit DAX measures, and single-direction
dimension-to-fact relationships. Raw CSV, raw BigQuery tables, and dbt staging
objects are not exposed to report users.

## Report preview

![Executive Overview](screenshots/executive-overview.png)

The complete report contains three pages:

1. Executive Overview
2. Crash Risk Factors
3. Geographic Crash Hotspots

## Live report

[View the interactive Power BI report](https://app.powerbi.com/view?r=eyJrIjoiNWI2MjVlYTktMzhkOC00MTkyLTg1ZDEtN2NmYWI5ZDI2MTQ1IiwidCI6ImM1NWUwZDRlLTM4YmQtNDllZS1hZGE0LWIzYzQ1MWI0NWU2MyIsImMiOjR9)

The published report is a portfolio demo built from public Chicago data and
contains no private business data or credentials.

## Directory structure

```text
bi/
├── README.md
├── screenshots/
└── Traffic Crashes Dashboard/
    ├── README.md
    ├── Traffic Crashes Dashboard.pbip
    ├── Traffic Crashes Dashboard.Report/
    └── Traffic Crashes Dashboard.SemanticModel/
```

## Future BI implementations

The `bi/` boundary allows future report implementations to consume the same
Gold-layer contracts without changing the warehouse. Possible extensions
include Tableau, Evidence, Rill, or another BI-as-code or visualization tool.
Those alternatives are not implemented in this repository yet.
