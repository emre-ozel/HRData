-- Cumulative Hires by Source
-- A "hire" = application with a decision_date and NO rejected interviews.
-- A full month spine from January of the earliest hire year ensures every
-- source has one row per month, including months with zero new hires.
with hires as (
    select
        dm.app_id,
        dm.source,
        dm.decision_date
    from {{ ref('dm_hiring_process') }} dm
    where dm.decision_date is not null
      and not exists (
          select 1
          from {{ ref('stg_interviews') }} i
          where i.app_id = dm.app_id
            and i.outcome = 'Rejected'
      )
),

month_spine as (
    select generate_series(
        date_trunc('year', min(decision_date)),
        date_trunc('month', max(decision_date)),
        interval '1 month'
    )::date as hire_month
    from hires
),

sources as (
    select distinct source from hires
),

spine as (
    select s.source, m.hire_month
    from sources s
    cross join month_spine m
),

monthly_hires as (
    select
        sp.source,
        sp.hire_month,
        count(h.app_id) as monthly_hires
    from spine sp
    left join hires h
        on  sp.source    = h.source
        and sp.hire_month = date_trunc('month', h.decision_date)::date
    group by sp.source, sp.hire_month
)

select
    source,
    hire_month,
    monthly_hires,
    sum(monthly_hires) over (
        partition by source
        order by hire_month
    ) as cumulative_hires
from monthly_hires
order by source, hire_month
