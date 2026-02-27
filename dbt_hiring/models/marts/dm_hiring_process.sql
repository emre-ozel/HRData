-- Data mart: one row per application with candidate info,
-- time-to-decision, and count of passed interviews.
with applications as (
    select * from {{ ref('stg_applications') }}
),

candidates as (
    select * from {{ ref('stg_candidates') }}
),

passed_counts as (
    select
        app_id,
        count(*) filter (where outcome = 'Passed') as passed_interviews_count
    from {{ ref('stg_interviews') }}
    group by app_id
)

select
    a.app_id,
    c.candidate_id,
    c.full_name,
    c.source,
    a.role_level,
    a.applied_date,
    a.decision_date,
    a.expected_salary,
    a.decision_date - a.applied_date           as time_to_decision_days,
    coalesce(pi.passed_interviews_count, 0)     as passed_interviews_count
from applications a
join candidates c using (candidate_id)
left join passed_counts pi using (app_id)
