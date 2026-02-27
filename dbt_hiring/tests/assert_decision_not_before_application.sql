-- Custom dbt test: flag applications where decision_date < applied_date
-- Mirrors Check 2 from 02_data_quality_checks.sql
select
    a.app_id,
    a.applied_date,
    a.decision_date
from {{ ref('stg_applications') }} a
where a.decision_date < a.applied_date
