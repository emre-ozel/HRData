# dbt Hiring Pipeline

A [dbt](https://docs.getdbt.com/) project that mirrors the raw-SQL ETL pipeline, adding schema tests, documentation, and a DAG-based build graph.

## Project Structure

```
dbt_hiring/
├── dbt_project.yml          # Project config
├── profiles.yml             # Connection profile (Postgres via Docker)
├── packages.yml             # dbt packages (dbt_utils)
├── models/
│   ├── staging/             # Source definitions + staging models
│   │   ├── src_hiring.yml   # Source schema (raw tables) with tests
│   │   ├── stg_staging.yml  # Staging model schema tests
│   │   ├── stg_candidates.sql
│   │   ├── stg_applications.sql
│   │   └── stg_interviews.sql   # Deduplicated via ROW_NUMBER()
│   ├── marts/
│   │   ├── dm_marts.yml
│   │   └── dm_hiring_process.sql   # One row per application
│   └── analytics/
│       ├── analytics.yml
│       ├── monthly_active_pipeline.sql
│       └── cumulative_hires_by_source.sql
└── tests/                   # Custom singular tests (data quality)
    ├── assert_interview_not_before_application.sql
    ├── assert_decision_not_before_application.sql
    └── assert_interviews_deduped.sql
```

## How It Maps to the Raw SQL Scripts

| Raw SQL File | dbt Equivalent |
|---|---|
| `00_setup_raw_tables.sql` | **Source** definition in `src_hiring.yml` (dbt reads the raw tables) |
| `01_dedup_and_clean.sql` | `stg_candidates`, `stg_applications`, `stg_interviews` models |
| `02_data_quality_checks.sql` | Schema tests in YAML + singular tests in `tests/` |
| `03_dm_hiring_process.sql` | `dm_hiring_process` mart model |
| `04_monthly_active_pipeline.sql` | `monthly_active_pipeline` analytics model |
| `05_cumulative_hires_by_source.sql` | `cumulative_hires_by_source` analytics model |

## Prerequisites

- Python 3.9+
- `dbt-postgres` (`pip install dbt-postgres`)
- The PostgreSQL container from the root `docker-compose.yml` must be running with raw tables loaded

## Quick Start

```bash
# 1. Start the database (from the project root)
docker compose up -d --wait

# 2. Enter the dbt project
cd dbt_hiring

# 3. Install dbt packages
dbt deps

# 4. Run all models
dbt run

# 5. Run all tests (schema + singular)
dbt test

# 6. Generate and serve documentation
dbt docs generate
dbt docs serve
```

## Notes

- `profiles.yml` is included in the project directory for portability. In production you would place it in `~/.dbt/`.
- All staging models are views (no data duplication). Mart and analytics models are also views but can be switched to `table` or `incremental` via `dbt_project.yml`.
- The singular test `assert_interview_not_before_application` is expected to **warn/fail** with the sample data (interview 13 is before app 6's applied_date). This is intentional — it mirrors DQ Check 1 from `02_data_quality_checks.sql`.
