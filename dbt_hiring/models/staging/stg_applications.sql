-- Staging: pass-through from raw_applications
with source as (
    select * from {{ source('hiring_raw', 'raw_applications') }}
)

select
    app_id,
    candidate_id,
    role_level,
    applied_date,
    decision_date,
    expected_salary
from source
