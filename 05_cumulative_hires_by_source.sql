-- ============================================================
-- 05_cumulative_hires_by_source.sql
-- Part B: Cumulative Hires by Source
-- A "hire" = application with a decision_date and NO rejected
-- interviews (all interviews passed or no interviews at all).
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
monthly_hires AS (
    SELECT
        source,
        DATE_TRUNC('month', decision_date)::DATE AS hire_month,
        COUNT(*)                                  AS monthly_hires
    FROM hires
    GROUP BY source, DATE_TRUNC('month', decision_date)
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
