-- ============================================================
-- 02_data_quality_checks.sql
-- Data quality validation queries (run as alerts)
-- ============================================================

-- -----------------------------------------------------------
-- Check 1: Interviews where interview_date < applied_date
-- -----------------------------------------------------------
SELECT
    'Interview before application' AS check_name,
    i.interview_id,
    i.app_id,
    i.interview_date,
    a.applied_date
FROM stg_interviews i
JOIN stg_applications a USING (app_id)
WHERE i.interview_date < a.applied_date;

-- -----------------------------------------------------------
-- Check 2: Applications where decision_date < applied_date
-- -----------------------------------------------------------
SELECT
    'Decision before application' AS check_name,
    a.app_id,
    a.applied_date,
    a.decision_date
FROM stg_applications a
WHERE a.decision_date < a.applied_date;

-- -----------------------------------------------------------
-- Check 3: Orphan interviews (no matching application)
-- -----------------------------------------------------------
SELECT
    'Orphan interview' AS check_name,
    i.interview_id,
    i.app_id
FROM stg_interviews i
LEFT JOIN stg_applications a USING (app_id)
WHERE a.app_id IS NULL;

-- -----------------------------------------------------------
-- Check 4: Orphan applications (no matching candidate)
-- -----------------------------------------------------------
SELECT
    'Orphan application' AS check_name,
    a.app_id,
    a.candidate_id
FROM stg_applications a
LEFT JOIN stg_candidates c USING (candidate_id)
WHERE c.candidate_id IS NULL;
