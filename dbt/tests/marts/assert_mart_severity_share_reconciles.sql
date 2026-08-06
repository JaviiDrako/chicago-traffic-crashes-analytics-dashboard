select
    sum(crash_share) as total_crash_share
from {{ ref('mart_severity_summary') }}
having abs(sum(crash_share) - 1) > 0.0001
