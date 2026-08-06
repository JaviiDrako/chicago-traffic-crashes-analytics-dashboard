-- Staging temporal fields must remain inside the source domain ranges.

select
    crash_record_id,
    crash_datetime,
    crash_hour,
    crash_day_of_week,
    crash_month
from {{ ref('stg_traffic_crashes') }}
where crash_hour not between 0 and 23
   or crash_day_of_week not between 1 and 7
   or crash_month not between 1 and 12
