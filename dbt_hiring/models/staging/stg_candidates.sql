-- Staging: pass-through from raw_candidates
with source as (
    select * from {{ source('hiring_raw', 'raw_candidates') }}
)

select
    candidate_id,
    full_name,
    source,
    profile_created_date
from source
