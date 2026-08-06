select
    weather_key,
    lighting_key,
    count(*) as duplicate_rows
from {{ ref('mart_risk_factors') }}
group by weather_key, lighting_key
having count(*) > 1
