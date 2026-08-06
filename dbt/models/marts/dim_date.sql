{{ config(
    materialized='table',
    alias='dim_date'
) }}

with observed_dates as (

    select distinct crash_date as full_date
    from {{ ref('stg_traffic_crashes') }}
    where crash_date is not null

)

select
    cast(format_date('%Y%m%d', full_date) as int64) as date_key,
    full_date,
    extract(year from full_date) as year,
    extract(quarter from full_date) as quarter,
    extract(month from full_date) as month,
    format_date('%B', full_date) as month_name,
    extract(week from full_date) as week_of_year,
    extract(day from full_date) as day_of_month,
    extract(dayofweek from full_date) as day_of_week,
    format_date('%A', full_date) as day_name,
    extract(dayofweek from full_date) in (1, 7) as is_weekend
from observed_dates
