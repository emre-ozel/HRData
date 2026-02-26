-- ============================================================
-- 00_setup_raw_tables.sql
-- Create raw tables and insert sample data for ATS pipeline
-- ============================================================

DROP TABLE IF EXISTS raw_interviews CASCADE;
DROP TABLE IF EXISTS raw_applications CASCADE;
DROP TABLE IF EXISTS raw_candidates CASCADE;

-- -----------------------------------------------------------
-- raw_candidates
-- -----------------------------------------------------------
CREATE TABLE raw_candidates (
    candidate_id         SERIAL PRIMARY KEY,
    full_name            VARCHAR(150) NOT NULL,
    source               VARCHAR(50)  NOT NULL,  -- LinkedIn, Referral, Career Page
    profile_created_date DATE         NOT NULL
);

-- -----------------------------------------------------------
-- raw_applications
-- -----------------------------------------------------------
CREATE TABLE raw_applications (
    app_id          SERIAL PRIMARY KEY,
    candidate_id    INT          NOT NULL REFERENCES raw_candidates(candidate_id),
    role_level      VARCHAR(30)  NOT NULL,  -- Junior, Senior, Executive
    applied_date    DATE         NOT NULL,
    decision_date   DATE,                   -- NULL = still active
    expected_salary NUMERIC(12,2) NOT NULL
);

-- -----------------------------------------------------------
-- raw_interviews
-- -----------------------------------------------------------
CREATE TABLE raw_interviews (
    interview_id   SERIAL PRIMARY KEY,
    app_id         INT         NOT NULL REFERENCES raw_applications(app_id),
    interview_date DATE        NOT NULL,
    outcome        VARCHAR(20) NOT NULL     -- Passed, Rejected, No Show
);

-- ============================================================
-- Sample data
-- ============================================================

-- Candidates (6 people, 3 sources)
INSERT INTO raw_candidates (candidate_id, full_name, source, profile_created_date) VALUES
(1,  'Alice Johnson',   'LinkedIn',    '2023-12-01'),
(2,  'Bob Smith',       'Referral',    '2024-01-15'),
(3,  'Carol Davis',     'Career Page', '2024-02-20'),
(4,  'Dan Wilson',      'LinkedIn',    '2024-01-05'),
(5,  'Eve Martinez',    'Referral',    '2024-03-10'),
(6,  'Frank Lee',       'Career Page', '2024-04-25');

-- Applications (10 rows, multiple role levels, some NULL decision_date)
INSERT INTO raw_applications (app_id, candidate_id, role_level, applied_date, decision_date, expected_salary) VALUES
(1,  1, 'Senior',    '2024-01-10', '2024-03-15', 95000),
(2,  1, 'Senior',    '2024-06-01', NULL,         100000),   -- Alice's 2nd app, still active
(3,  2, 'Junior',    '2024-02-01', '2024-04-10', 55000),
(4,  3, 'Executive', '2024-03-05', '2024-05-20', 150000),
(5,  4, 'Senior',    '2024-01-20', '2024-02-28', 90000),
(6,  4, 'Junior',    '2024-07-01', NULL,         60000),    -- Dan's 2nd app, still active
(7,  5, 'Senior',    '2024-04-15', '2024-06-30', 105000),
(8,  5, 'Executive', '2024-08-01', NULL,         140000),   -- Eve's 2nd app, still active
(9,  6, 'Junior',    '2024-05-10', '2024-07-15', 50000),
(10, 3, 'Senior',    '2024-09-01', NULL,         120000);   -- Carol's 2nd app, still active

-- Interviews (15 rows including duplicates and edge cases)
INSERT INTO raw_interviews (interview_id, app_id, interview_date, outcome) VALUES
-- App 1 (Alice Senior): 2 passed interviews
(1,  1, '2024-01-25', 'Passed'),
(2,  1, '2024-02-10', 'Passed'),
-- App 3 (Bob Junior): 1 passed, 1 rejected
(3,  3, '2024-02-15', 'Passed'),
(4,  3, '2024-03-01', 'Rejected'),
-- App 4 (Carol Executive): 2 passed
(5,  4, '2024-03-20', 'Passed'),
(6,  4, '2024-04-05', 'Passed'),
-- App 5 (Dan Senior): 1 passed
(7,  5, '2024-02-01', 'Passed'),
-- App 7 (Eve Senior): 2 passed
(8,  7, '2024-05-01', 'Passed'),
(9,  7, '2024-05-20', 'Passed'),
-- App 9 (Frank Junior): 1 passed
(10, 9, '2024-05-25', 'Passed'),

-- DUPLICATE: same (app_id, interview_date, outcome) as interview_id=1
(11, 1, '2024-01-25', 'Passed'),

-- DUPLICATE: same (app_id, interview_date, outcome) as interview_id=8
(12, 7, '2024-05-01', 'Passed'),

-- EDGE CASE: interview_date BEFORE applied_date (app 6 applied 2024-07-01)
(13, 6, '2024-06-20', 'No Show'),

-- App 2 (Alice 2nd, active): 1 No Show interview
(14, 2, '2024-06-15', 'No Show'),

-- App 8 (Eve Executive, active): 1 passed interview
(15, 8, '2024-08-10', 'Passed');

-- Reset sequences so future inserts get correct IDs
SELECT setval('raw_candidates_candidate_id_seq', (SELECT MAX(candidate_id) FROM raw_candidates));
SELECT setval('raw_applications_app_id_seq',     (SELECT MAX(app_id)        FROM raw_applications));
SELECT setval('raw_interviews_interview_id_seq',  (SELECT MAX(interview_id)  FROM raw_interviews));
