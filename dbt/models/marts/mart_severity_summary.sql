{{ config(
    materialized='table',
    alias='mart_severity_summary'
) }}

with severity_counts as (

    select
        sev.severity_key,
        sev.severity_label,
        sev.severity_group,
        sev.severity_rank,
        sev.is_fatal_severity,
        sev.is_injury_severity,
        count(*) as crash_count,
        sum(f.injuries_total) as total_injuries,
        sum(f.injuries_fatal) as total_fatal_injuries
    from {{ ref('fct_traffic_crashes') }} as f
    inner join {{ ref('dim_severity') }} as sev
        on f.severity_key = sev.severity_key
    group by
        sev.severity_key,
        sev.severity_label,
        sev.severity_group,
        sev.severity_rank,
        sev.is_fatal_severity,
        sev.is_injury_severity

), totals as (

    select sum(crash_count) as total_crashes
    from severity_counts

)

select
    s.severity_key,
    s.severity_label,
    s.severity_group,
    s.severity_rank,
    s.is_fatal_severity,
    s.is_injury_severity,
    s.crash_count,
    safe_divide(s.crash_count, t.total_crashes) as crash_share,
    s.total_injuries,
    s.total_fatal_injuries
from severity_counts as s
cross join totals as t
