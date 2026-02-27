-- ============================================================
-- 05_cumulative_hires_by_source.sql
-- Part B: Cumulative Hires by Source
-- A "hire" = application with a decision_date and NO rejected
-- interviews (all interviews passed or no interviews at all).
--
-- A full month spine is generated from January of the earliest
-- hire year through the latest hire month, cross-joined with
-- every source so that zero-hire months still appear with a
-- running cumulative total carried forward.
-- ============================================================

WITH hires AS (
    SELECT
        dm.app_id,
        dm.source,
        dm.decision_date
    FROM dm_hiring_process dm
    WHERE dm.decision_date IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM stg_interviews i
          WHERE i.app_id = dm.app_id
            AND i.outcome = 'Rejected'
      )
),

-- Full month series starting from Jan of the earliest hire year
month_spine AS (
    SELECT generate_series(
        DATE_TRUNC('year', MIN(decision_date)),
        DATE_TRUNC('month', MAX(decision_date)),
        INTERVAL '1 month'
    )::DATE AS hire_month
    FROM hires
),

-- Every source that recorded at least one hire
sources AS (
    SELECT DISTINCT source FROM hires
),

-- Cartesian product: one row per (source, month)
spine AS (
    SELECT s.source, m.hire_month
    FROM sources s
    CROSS JOIN month_spine m
),

-- Actual hire counts per source-month
monthly_hires AS (
    SELECT
        sp.source,
        sp.hire_month,
        COUNT(h.app_id) AS monthly_hires
    FROM spine sp
    LEFT JOIN hires h
        ON  sp.source     = h.source
        AND sp.hire_month  = DATE_TRUNC('month', h.decision_date)::DATE
    GROUP BY sp.source, sp.hire_month
)

SELECT
    source,
    hire_month,
    monthly_hires,
    SUM(monthly_hires) OVER (
        PARTITION BY source
        ORDER BY hire_month
    ) AS cumulative_hires
FROM monthly_hires
ORDER BY source, hire_month;
