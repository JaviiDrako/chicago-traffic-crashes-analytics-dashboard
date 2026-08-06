{{ config(
    materialized='table',
    alias='mart_risk_factors'
) }}

select
    w.weather_key,
    w.weather_condition,
    w.weather_group,
    l.lighting_key,
    l.lighting_condition,
    l.lighting_group,
    count(*) as crash_count,
    countif(f.is_injury_crash) as injury_crash_count,
    countif(f.is_fatal_crash) as fatal_crash_count,
    sum(f.injuries_total) as total_injuries,
    sum(f.injuries_fatal) as total_fatal_injuries,
    safe_divide(countif(f.is_injury_crash), count(*)) as injury_crash_rate,
    safe_divide(countif(f.is_fatal_crash), count(*)) as fatal_crash_rate,
    avg(f.posted_speed_limit) as average_posted_speed_limit,
    avg(f.unit_count) as average_units_per_crash
from {{ ref('fct_traffic_crashes') }} as f
inner join {{ ref('dim_weather') }} as w
    on f.weather_key = w.weather_key
inner join {{ ref('dim_lighting') }} as l
    on f.lighting_key = l.lighting_key
group by
    w.weather_key,
    w.weather_condition,
    w.weather_group,
    l.lighting_key,
    l.lighting_condition,
    l.lighting_group
