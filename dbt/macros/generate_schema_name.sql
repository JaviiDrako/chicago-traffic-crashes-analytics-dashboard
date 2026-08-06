{#
  Keep custom dbt schemas as explicit BigQuery datasets.

  dbt's default macro prefixes a custom schema with the target dataset. That
  behavior is useful for isolated environments, but this project already has
  named BigQuery datasets for development and analytics. Returning the custom
  name directly keeps marts in traffic_crashes_analytics while staging remains
  in the target dataset (traffic_crashes_dev locally).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
