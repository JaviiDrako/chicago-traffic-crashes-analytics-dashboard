{{ config(
    materialized='table',
    alias='mart_crashes_daily'
) }}

select
    d.date_key,
    d.full_date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week_of_year,
    d.day_of_week,
    d.day_name,
    d.is_weekend,
    count(*) as crash_count,
    countif(f.is_injury_crash) as injury_crash_count,
    countif(f.is_fatal_crash) as fatal_crash_count,
    sum(f.injuries_total) as total_injuries,
    sum(f.injuries_fatal) as total_fatal_injuries,
    avg(f.posted_speed_limit) as average_posted_speed_limit,
    avg(f.unit_count) as average_units_per_crash
from {{ ref('fct_traffic_crashes') }} as f
inner join {{ ref('dim_date') }} as d
    on f.date_key = d.date_key
group by
    d.date_key,
    d.full_date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week_of_year,
    d.day_of_week,
    d.day_name,
    d.is_weekend
