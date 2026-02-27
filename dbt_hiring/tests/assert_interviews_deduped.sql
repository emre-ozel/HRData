-- Custom dbt test: stg_interviews should have no duplicates
-- after dedup. Verify (app_id, interview_date, outcome) is unique.
select
    app_id,
    interview_date,
    outcome,
    count(*) as cnt
from {{ ref('stg_interviews') }}
group by app_id, interview_date, outcome
having count(*) > 1
