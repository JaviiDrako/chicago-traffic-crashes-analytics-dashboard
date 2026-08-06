select
    crash_record_id,
    injuries_total,
    injuries_fatal,
    crash_count
from {{ ref('fct_traffic_crashes') }}
where injuries_total < 0
   or injuries_fatal < 0
   or injuries_fatal > injuries_total
   or crash_count != 1
