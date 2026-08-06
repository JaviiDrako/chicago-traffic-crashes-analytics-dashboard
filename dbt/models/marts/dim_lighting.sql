{{ config(
    materialized='table',
    alias='dim_lighting'
) }}

with distinct_conditions as (

    select distinct
        coalesce(nullif(trim(lighting_condition), ''), 'Unknown') as lighting_condition
    from {{ ref('stg_traffic_crashes') }}

), grouped_conditions as (

    select
        lighting_condition,
        case
            when lower(lighting_condition) like '%daylight%' then 'Daylight'
            when lower(lighting_condition) like '%dawn%'
                or lower(lighting_condition) like '%dusk%' then 'Dawn or dusk'
            when lower(lighting_condition) like '%darkness%' then 'Darkness'
            when lower(lighting_condition) like '%dark%' then 'Darkness'
            else 'Other or unknown'
        end as lighting_group
    from distinct_conditions

)

select
    farm_fingerprint(concat('lighting|', lighting_condition)) as lighting_key,
    lighting_condition,
    lighting_group
from grouped_conditions
