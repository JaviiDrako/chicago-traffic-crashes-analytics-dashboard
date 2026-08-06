-- Binary indicator columns in the raw source should contain only Y, N or NULL.

with source as (

    select
        CRASH_RECORD_ID as crash_record_id,
        [
            struct('CRASH_DATE_EST_I' as field_name, CRASH_DATE_EST_I as field_value),
            struct('INTERSECTION_RELATED_I' as field_name, INTERSECTION_RELATED_I as field_value),
            struct('NOT_RIGHT_OF_WAY_I' as field_name, NOT_RIGHT_OF_WAY_I as field_value),
            struct('HIT_AND_RUN_I' as field_name, HIT_AND_RUN_I as field_value),
            struct('PHOTOS_TAKEN_I' as field_name, PHOTOS_TAKEN_I as field_value),
            struct('STATEMENTS_TAKEN_I' as field_name, STATEMENTS_TAKEN_I as field_value),
            struct('DOORING_I' as field_name, DOORING_I as field_value),
            struct('WORK_ZONE_I' as field_name, WORK_ZONE_I as field_value),
            struct('WORKERS_PRESENT_I' as field_name, WORKERS_PRESENT_I as field_value)
        ] as binary_fields
    from {{ source('traffic_crashes_raw', 'raw_traffic_crashes') }}

)

select
    crash_record_id,
    field_name,
    field_value
from source, unnest(binary_fields)
where nullif(trim(field_value), '') is not null
  and upper(trim(field_value)) not in ('Y', 'N')
