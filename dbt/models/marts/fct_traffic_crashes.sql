{{ config(
    materialized='table',
    alias='fct_traffic_crashes'
) }}

with staging as (

    select *
    from {{ ref('stg_traffic_crashes') }}

), joined_dimensions as (

    select
        s.*,
        d.date_key,
        w.weather_key,
        l.lighting_key,
        sev.severity_key
    from staging as s
    left join {{ ref('dim_date') }} as d
        on s.crash_date = d.full_date
    left join {{ ref('dim_weather') }} as w
        on coalesce(nullif(trim(s.weather_condition), ''), 'Unknown') = w.weather_condition
    left join {{ ref('dim_lighting') }} as l
        on coalesce(nullif(trim(s.lighting_condition), ''), 'Unknown') = l.lighting_condition
    left join {{ ref('dim_severity') }} as sev
        on coalesce(nullif(trim(s.most_severe_injury), ''), 'Unknown') = sev.severity_label

)

select
    crash_record_id,
    date_key,
    weather_key,
    lighting_key,
    severity_key,

    crash_datetime,
    crash_date,
    crash_year,
    crash_month,
    crash_month_name,
    crash_day_of_week,
    crash_day_name,
    crash_hour,

    crash_type,
    first_crash_type,
    damage,
    trafficway_type,
    traffic_control_device,
    device_condition,
    roadway_surface_condition,
    road_defect,
    alignment,
    report_type,
    primary_contributory_cause,
    secondary_contributory_cause,
    street_number,
    street_direction,
    street_name,
    beat_of_occurrence,

    posted_speed_limit,
    lane_count,
    unit_count,
    most_severe_injury,
    coalesce(injuries_total, 0) as injuries_total,
    coalesce(injuries_fatal, 0) as injuries_fatal,
    coalesce(injuries_incapacitating, 0) as injuries_incapacitating,
    coalesce(injuries_non_incapacitating, 0) as injuries_non_incapacitating,
    coalesce(injuries_reported_not_evident, 0) as injuries_reported_not_evident,
    coalesce(injuries_no_indication, 0) as injuries_no_indication,
    coalesce(injuries_unknown, 0) as injuries_unknown,

    crash_date_estimated_flag,
    intersection_related_flag,
    not_right_of_way_flag,
    hit_and_run_flag,
    photos_taken_flag,
    statements_taken_flag,
    dooring_flag,
    work_zone_flag,
    work_zone_type,
    workers_present_flag,
    is_injury_crash,
    is_fatal_crash,
    has_coordinates,
    latitude,
    longitude,
    location_wkt,
    idot_control_number,
    police_notified_datetime,

    1 as crash_count
from joined_dimensions
