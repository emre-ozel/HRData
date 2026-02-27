-- Monthly Active Pipeline
-- An application is "active" in a month if the reporting month falls
-- between applied_date and COALESCE(decision_date, CURRENT_DATE).
-- One row per (report_month, app_id) pair is generated, then aggregated.
with month_series as (
    select generate_series(
        date_trunc('month', min(applied_date)),
        date_trunc('month', greatest(
            max(coalesce(decision_date, current_date)),
            max(applied_date)
        )),
        interval '1 month'
    )::date as report_month
    from {{ ref('stg_applications') }}
)

select
    ms.report_month,
    count(a.app_id) as active_application_count
from month_series ms
left join {{ ref('stg_applications') }} a
    on ms.report_month >= date_trunc('month', a.applied_date)
   and ms.report_month <= date_trunc('month', coalesce(a.decision_date, current_date))
group by ms.report_month
order by ms.report_month
