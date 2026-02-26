-- ============================================================
-- 04_monthly_active_pipeline.sql
-- Part B: Monthly Active Pipeline report
-- An application is "active" in a month if the month falls
-- between applied_date and COALESCE(decision_date, CURRENT_DATE).
-- ============================================================

WITH month_series AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(applied_date)),
        DATE_TRUNC('month', GREATEST(
            MAX(COALESCE(decision_date, CURRENT_DATE)),
            MAX(applied_date)
        )),
        INTERVAL '1 month'
    )::DATE AS report_month
    FROM stg_applications
)
SELECT
    ms.report_month,
    COUNT(a.app_id) AS active_application_count
FROM month_series ms
LEFT JOIN stg_applications a
    ON ms.report_month >= DATE_TRUNC('month', a.applied_date)
   AND ms.report_month <= DATE_TRUNC('month', COALESCE(a.decision_date, CURRENT_DATE))
GROUP BY ms.report_month
ORDER BY ms.report_month;
