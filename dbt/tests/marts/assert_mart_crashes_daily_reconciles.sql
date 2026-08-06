with fact_totals as (

    select sum(crash_count) as fact_crash_count
    from {{ ref('fct_traffic_crashes') }}

), daily_totals as (

    select sum(crash_count) as daily_crash_count
    from {{ ref('mart_crashes_daily') }}

)

select
    fact_crash_count,
    daily_crash_count
from fact_totals
cross join daily_totals
where fact_crash_count != daily_crash_count
