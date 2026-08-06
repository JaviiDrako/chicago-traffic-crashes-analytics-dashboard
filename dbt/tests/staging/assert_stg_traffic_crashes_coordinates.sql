-- Non-null coordinates should fall inside a broad Chicago-area bounding box.

select
    crash_record_id,
    latitude,
    longitude
from {{ ref('stg_traffic_crashes') }}
where has_coordinates
  and (
      latitude not between 41 and 43
      or longitude not between -88 and -87
  )
