{{ config(
    materialized='table',
    alias='dim_weather'
) }}

with distinct_conditions as (

    select distinct
        coalesce(nullif(trim(weather_condition), ''), 'Unknown') as weather_condition
    from {{ ref('stg_traffic_crashes') }}

), grouped_conditions as (

    select
        weather_condition,
        case
            when lower(weather_condition) like '%clear%' then 'Clear'
            when lower(weather_condition) like '%rain%'
                or lower(weather_condition) like '%drizzle%' then 'Rain'
            when lower(weather_condition) like '%snow%'
                or lower(weather_condition) like '%sleet%' then 'Snow or ice'
            when lower(weather_condition) like '%fog%'
                or lower(weather_condition) like '%haze%'
                or lower(weather_condition) like '%smoke%' then 'Reduced visibility'
            when lower(weather_condition) like '%cloud%'
                or lower(weather_condition) like '%overcast%' then 'Cloudy or overcast'
            when lower(weather_condition) like '%wind%' then 'Windy'
            when lower(weather_condition) like '%blowing%' then 'Blowing particles'
            else 'Other or unknown'
        end as weather_group
    from distinct_conditions

)

select
    farm_fingerprint(concat('weather|', weather_condition)) as weather_key,
    weather_condition,
    weather_group
from grouped_conditions
