-- ============================================================
-- 03_dm_hiring_process.sql
-- Data mart view: one row per application with metrics
-- ============================================================

DROP VIEW IF EXISTS dm_hiring_process CASCADE;

CREATE VIEW dm_hiring_process AS
SELECT
    a.app_id,
    c.candidate_id,
    c.full_name,
    c.source,
    a.role_level,
    a.applied_date,
    a.decision_date,
    a.expected_salary,
    a.decision_date - a.applied_date           AS time_to_decision_days,
    COALESCE(pi.passed_interviews_count, 0)     AS passed_interviews_count
FROM stg_applications a
JOIN stg_candidates c USING (candidate_id)
LEFT JOIN (
    SELECT
        app_id,
        COUNT(*) FILTER (WHERE outcome = 'Passed') AS passed_interviews_count
    FROM stg_interviews
    GROUP BY app_id
) pi USING (app_id);
