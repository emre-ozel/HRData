-- Custom dbt test: flag interviews where interview_date < applied_date
-- Mirrors Check 1 from 02_data_quality_checks.sql
-- A non-empty result set means the test WARNS (known data quality issue).
-- {{ config(severity='warn') }}
select
    i.interview_id,
    i.app_id,
    i.interview_date,
    a.applied_date
from {{ ref('stg_interviews') }} i
join {{ ref('stg_applications') }} a using (app_id)
where i.interview_date < a.applied_date
