{{ config(
    materialized='table',
    alias='dim_severity'
) }}

with distinct_severity as (

    select distinct
        coalesce(nullif(trim(most_severe_injury), ''), 'Unknown') as severity_label
    from {{ ref('stg_traffic_crashes') }}

), classified as (

    select
        severity_label,
        case
            when lower(severity_label) like '%fatal%' then 'Fatal injury'
            when lower(severity_label) like '%nonincapacitating%' then 'Non-incapacitating injury'
            when lower(severity_label) like '%incapacitating%' then 'Incapacitating injury'
            when lower(severity_label) like '%reported%'
                or lower(severity_label) like '%evident%' then 'Reported injury'
            when lower(severity_label) like '%no indication%' then 'No injury indicated'
            else 'Other or unknown'
        end as severity_group,
        case
            when lower(severity_label) like '%fatal%' then 1
            when lower(severity_label) like '%nonincapacitating%' then 3
            when lower(severity_label) like '%incapacitating%' then 2
            when lower(severity_label) like '%reported%'
                or lower(severity_label) like '%evident%' then 4
            when lower(severity_label) like '%no indication%' then 5
            else 99
        end as severity_rank,
        lower(severity_label) like '%fatal%' as is_fatal_severity,
        lower(severity_label) not like '%no indication%'
            and lower(severity_label) not like '%unknown%' as is_injury_severity
    from distinct_severity

)

select
    farm_fingerprint(concat('severity|', severity_label)) as severity_key,
    severity_label,
    severity_group,
    severity_rank,
    is_fatal_severity,
    is_injury_severity
from classified
