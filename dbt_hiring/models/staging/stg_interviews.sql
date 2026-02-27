-- Staging: deduplicate raw_interviews on (app_id, interview_date, outcome).
-- Keeps the row with the lowest interview_id per group.
with ranked as (
    select
        interview_id,
        app_id,
        interview_date,
        outcome,
        row_number() over (
            partition by app_id, interview_date, outcome
            order by interview_id
        ) as rn
    from {{ source('hiring_raw', 'raw_interviews') }}
)

select
    interview_id,
    app_id,
    interview_date,
    outcome
from ranked
where rn = 1
