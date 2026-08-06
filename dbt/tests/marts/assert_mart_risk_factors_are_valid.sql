select
    weather_key,
    lighting_key,
    injury_crash_rate,
    fatal_crash_rate
from {{ ref('mart_risk_factors') }}
where injury_crash_rate < 0
   or injury_crash_rate > 1
   or fatal_crash_rate < 0
   or fatal_crash_rate > 1
