-- ============================================================
-- 01_dedup_and_clean.sql
-- Deduplicate and create staging views
-- ============================================================

-- -----------------------------------------------------------
-- stg_candidates: pass-through staging view
-- -----------------------------------------------------------
DROP VIEW IF EXISTS stg_candidates CASCADE;

CREATE VIEW stg_candidates AS
SELECT
    candidate_id,
    full_name,
    source,
    profile_created_date
FROM raw_candidates;

-- -----------------------------------------------------------
-- stg_applications: pass-through staging view
-- -----------------------------------------------------------
DROP VIEW IF EXISTS stg_applications CASCADE;

CREATE VIEW stg_applications AS
SELECT
    app_id,
    candidate_id,
    role_level,
    applied_date,
    decision_date,
    expected_salary
FROM raw_applications;

-- -----------------------------------------------------------
-- stg_interviews: deduplicated on (app_id, interview_date, outcome)
-- Keeps the row with the lowest interview_id per group.
-- -----------------------------------------------------------
DROP VIEW IF EXISTS stg_interviews CASCADE;

CREATE VIEW stg_interviews AS
SELECT
    interview_id,
    app_id,
    interview_date,
    outcome
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY app_id, interview_date, outcome
            ORDER BY interview_id
        ) AS rn
    FROM raw_interviews
) t
WHERE rn = 1;
