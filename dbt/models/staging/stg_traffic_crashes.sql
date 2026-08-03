{{ config(
    materialized='view',
    alias='stg_traffic_crashes'
) }}

with source as (

    select *
    from {{ source('traffic_crashes_raw', 'raw_traffic_crashes') }}

), typed as (

    select
        nullif(trim(CRASH_RECORD_ID), '') as crash_record_id,

        case
            when upper(nullif(trim(CRASH_DATE_EST_I), '')) = 'Y' then true
            when upper(nullif(trim(CRASH_DATE_EST_I), '')) = 'N' then false
        end as crash_date_estimated_flag,

        safe.parse_datetime(
            '%m/%d/%Y %I:%M:%S %p',
            nullif(trim(CRASH_DATE), '')
        ) as crash_datetime,

        safe_cast(POSTED_SPEED_LIMIT as int64) as posted_speed_limit,
        nullif(trim(TRAFFIC_CONTROL_DEVICE), '') as traffic_control_device,
        nullif(trim(DEVICE_CONDITION), '') as device_condition,
        nullif(trim(WEATHER_CONDITION), '') as weather_condition,
        nullif(trim(LIGHTING_CONDITION), '') as lighting_condition,
        nullif(trim(FIRST_CRASH_TYPE), '') as first_crash_type,
        nullif(trim(TRAFFICWAY_TYPE), '') as trafficway_type,
        safe_cast(LANE_CNT as int64) as lane_count,
        nullif(trim(ALIGNMENT), '') as alignment,
        nullif(trim(ROADWAY_SURFACE_COND), '') as roadway_surface_condition,
        nullif(trim(ROAD_DEFECT), '') as road_defect,
        nullif(trim(REPORT_TYPE), '') as report_type,
        nullif(trim(CRASH_TYPE), '') as crash_type,

        case
            when upper(nullif(trim(INTERSECTION_RELATED_I), '')) = 'Y' then true
            when upper(nullif(trim(INTERSECTION_RELATED_I), '')) = 'N' then false
        end as intersection_related_flag,

        case
            when upper(nullif(trim(NOT_RIGHT_OF_WAY_I), '')) = 'Y' then true
            when upper(nullif(trim(NOT_RIGHT_OF_WAY_I), '')) = 'N' then false
        end as not_right_of_way_flag,

        case
            when upper(nullif(trim(HIT_AND_RUN_I), '')) = 'Y' then true
            when upper(nullif(trim(HIT_AND_RUN_I), '')) = 'N' then false
        end as hit_and_run_flag,

        nullif(trim(DAMAGE), '') as damage,
        safe.parse_datetime(
            '%m/%d/%Y %I:%M:%S %p',
            nullif(trim(DATE_POLICE_NOTIFIED), '')
        ) as police_notified_datetime,
        nullif(trim(PRIM_CONTRIBUTORY_CAUSE), '') as primary_contributory_cause,
        nullif(trim(SEC_CONTRIBUTORY_CAUSE), '') as secondary_contributory_cause,
        safe_cast(STREET_NO as int64) as street_number,
        nullif(trim(STREET_DIRECTION), '') as street_direction,
        nullif(trim(STREET_NAME), '') as street_name,
        safe_cast(BEAT_OF_OCCURRENCE as int64) as beat_of_occurrence,

        case
            when upper(nullif(trim(PHOTOS_TAKEN_I), '')) = 'Y' then true
            when upper(nullif(trim(PHOTOS_TAKEN_I), '')) = 'N' then false
        end as photos_taken_flag,

        case
            when upper(nullif(trim(STATEMENTS_TAKEN_I), '')) = 'Y' then true
            when upper(nullif(trim(STATEMENTS_TAKEN_I), '')) = 'N' then false
        end as statements_taken_flag,

        case
            when upper(nullif(trim(DOORING_I), '')) = 'Y' then true
            when upper(nullif(trim(DOORING_I), '')) = 'N' then false
        end as dooring_flag,

        case
            when upper(nullif(trim(WORK_ZONE_I), '')) = 'Y' then true
            when upper(nullif(trim(WORK_ZONE_I), '')) = 'N' then false
        end as work_zone_flag,

        nullif(trim(WORK_ZONE_TYPE), '') as work_zone_type,

        case
            when upper(nullif(trim(WORKERS_PRESENT_I), '')) = 'Y' then true
            when upper(nullif(trim(WORKERS_PRESENT_I), '')) = 'N' then false
        end as workers_present_flag,

        safe_cast(NUM_UNITS as int64) as unit_count,
        safe_cast(CRASH_MONTH as int64) as crash_month,
        nullif(trim(MOST_SEVERE_INJURY), '') as most_severe_injury,
        safe_cast(INJURIES_TOTAL as float64) as injuries_total,
        safe_cast(INJURIES_FATAL as float64) as injuries_fatal,
        safe_cast(INJURIES_INCAPACITATING as float64) as injuries_incapacitating,
        safe_cast(INJURIES_NON_INCAPACITATING as float64) as injuries_non_incapacitating,
        safe_cast(INJURIES_REPORTED_NOT_EVIDENT as float64) as injuries_reported_not_evident,
        safe_cast(INJURIES_NO_INDICATION as float64) as injuries_no_indication,
        safe_cast(INJURIES_UNKNOWN as float64) as injuries_unknown,
        safe_cast(CRASH_HOUR as int64) as crash_hour,
        safe_cast(CRASH_DAY_OF_WEEK as int64) as crash_day_of_week,
        nullif(trim(IDOT_CONTROL_NO), '') as idot_control_number,

        case
            when safe_cast(LATITUDE as float64) = 0
                and safe_cast(LONGITUDE as float64) = 0 then null
            else safe_cast(LATITUDE as float64)
        end as latitude,

        case
            when safe_cast(LATITUDE as float64) = 0
                and safe_cast(LONGITUDE as float64) = 0 then null
            else safe_cast(LONGITUDE as float64)
        end as longitude,

        nullif(trim(LOCATION), '') as location_wkt

    from source

), enriched as (

    select
        typed.*,
        date(crash_datetime) as crash_date,
        extract(year from crash_datetime) as crash_year,
        format_date('%B', date(crash_datetime)) as crash_month_name,
        format_date('%A', date(crash_datetime)) as crash_day_name,
        latitude is not null and longitude is not null as has_coordinates,
        coalesce(injuries_total, 0) > 0 as is_injury_crash,
        coalesce(injuries_fatal, 0) > 0 as is_fatal_crash
    from typed

)

select *
from enriched
