# Data Engineer Assessment — Hiring Pipeline Data Warehouse

A complete ETL pipeline and analytical SQL solution for an Applicant Tracking System (ATS), built on PostgreSQL.

## Overview

The solution moves raw HR hiring data through a structured pipeline:

```
Raw Tables  -->  Staging (dedup + clean)  -->  Data Mart  -->  Analytical Queries
   00                    01                       03              04, 05
                                    02 (quality checks run alongside)
```

### Architecture

| Layer | Tables / Views | Purpose |
|-------|---------------|---------|
| **Raw** | `raw_candidates`, `raw_applications`, `raw_interviews` | Source-of-truth ingestion tables with sample data |
| **Staging** | `stg_candidates`, `stg_applications`, `stg_interviews` | Cleaned views; `stg_interviews` deduplicates on `(app_id, interview_date, outcome)` |
| **Data Mart** | `dm_hiring_process` | One row per application with candidate info, time-to-decision, and passed-interview count |
| **Analytics** | Monthly Active Pipeline, Cumulative Hires by Source | Business-facing reports |

## File Descriptions

| File | Purpose |
|------|---------|
| `00_setup_raw_tables.sql` | DDL + sample data (6 candidates, 10 applications, 15 interviews). Includes intentional edge cases: duplicate interviews, a pre-application interview date, and NULL decision dates for active applications. |
| `01_dedup_and_clean.sql` | Creates staging views. `stg_interviews` uses `ROW_NUMBER()` partitioned by `(app_id, interview_date, outcome)` to keep only the first occurrence, removing duplicates. |
| `02_data_quality_checks.sql` | Four validation queries that flag: (1) interviews before application date, (2) decisions before application date, (3) orphan interviews, (4) orphan applications. |
| `03_dm_hiring_process.sql` | `dm_hiring_process` view joining all staging tables. Computes `time_to_decision_days` and `passed_interviews_count` per application. |
| `04_monthly_active_pipeline.sql` | Generates a month series via `generate_series()` and counts applications active in each month (between `applied_date` and `COALESCE(decision_date, CURRENT_DATE)`). |
| `05_cumulative_hires_by_source.sql` | Identifies hires (decided applications with no failed interviews), groups by source and month, and computes a running cumulative total using `SUM() OVER()`. |

## Prerequisites

- **Docker** and **Docker Compose** (v2)

That's it. No local PostgreSQL installation needed.

## How to Run

### Option A: One command (recommended)

```bash
./run_all.sh
```

This will:
1. Start a PostgreSQL 16 container
2. Automatically execute `00`, `01`, and `03` (via `docker-entrypoint-initdb.d`)
3. Run the data quality checks (`02`) and display flagged rows
4. Query the `dm_hiring_process` data mart
5. Run the monthly active pipeline report (`04`)
6. Run the cumulative hires by source report (`05`)

### Option B: Step by step

```bash
# 1. Start the database (00, 01, 03 run automatically on first start)
docker compose up -d --wait

# 2. Run any script manually
docker exec ats_dwh psql -U ats_user -d ats -f /sql/02_data_quality_checks.sql
docker exec ats_dwh psql -U ats_user -d ats -f /sql/04_monthly_active_pipeline.sql
docker exec ats_dwh psql -U ats_user -d ats -f /sql/05_cumulative_hires_by_source.sql

# 3. Open an interactive psql session
docker exec -it ats_dwh psql -U ats_user -d ats
```

### Reset the database

If you modify the SQL files and want a fresh start:

```bash
docker compose down -v   # removes the data volume
./run_all.sh             # re-creates everything from scratch
```

## Expected Output

### Data Quality Checks (`02`)

Check 1 should flag **1 row** — interview ID 13 for app 6, where the interview date (`2024-06-20`) is before the application date (`2024-07-01`).

Checks 2, 3, and 4 should return **0 rows** (no violations in the sample data for those checks).

### Data Mart (`03`)

Returns **10 rows** (one per application) with columns:

| Column | Description |
|--------|-------------|
| `app_id` | Application identifier |
| `full_name` | Candidate name |
| `source` | Recruitment channel (LinkedIn, Referral, Career Page) |
| `role_level` | Junior / Senior / Executive |
| `applied_date` | When the candidate applied |
| `decision_date` | When a decision was made (NULL if active) |
| `expected_salary` | Candidate's salary expectation |
| `time_to_decision_days` | Days from application to decision (NULL if active) |
| `passed_interviews_count` | Number of interviews with outcome = 'Passed' |

### Monthly Active Pipeline (`04`)

Shows one row per month from January 2024 onward, with the count of applications that were active during that month.

### Cumulative Hires by Source (`05`)

A hire is defined as an application that has a `decision_date` **and** no "Rejected" interviews. A full month spine is generated from January of the earliest hire year through the latest hire month, cross-joined with every source. This ensures every source has one row per month — including zero-hire months — with the cumulative total carried forward.

## dbt Project (Nice-to-Have)

The `dbt_hiring/` directory contains a full [dbt](https://docs.getdbt.com/) project that mirrors the raw SQL pipeline above. It provides:

- **Source definitions** with built-in schema tests (uniqueness, not-null, accepted values, referential integrity)
- **Staging, mart, and analytics models** identical in logic to the raw SQL scripts
- **Singular tests** that replicate the data quality checks from `02_data_quality_checks.sql`
- **Auto-generated documentation** via `dbt docs generate`

See [`dbt_hiring/README.md`](dbt_hiring/README.md) for setup instructions.

## Design Decisions

1. **Views over materialized tables for staging**: Staging layers are PostgreSQL views. This keeps the solution simple and ensures staging always reflects the latest raw data. In production, these would likely become materialized views or physical tables refreshed by an orchestrator.

2. **Deduplication strategy**: `ROW_NUMBER()` partitioned by the natural key `(app_id, interview_date, outcome)`, ordered by `interview_id` ASC. This deterministically keeps the earliest-inserted record.

3. **"Hire" definition**: An application with a non-NULL `decision_date` and zero "Rejected" interview outcomes. This was chosen because the sample data does not include an explicit `status` column on applications.

4. **Active pipeline window**: An application is considered active from its `applied_date` month through its `decision_date` month (or `CURRENT_DATE` if still open). This uses month-level granularity via `DATE_TRUNC`.

## Connection Details

| Parameter | Value |
|-----------|-------|
| Host | `localhost` |
| Port | `5432` |
| Database | `ats` |
| User | `ats_user` |
| Password | `ats_pass` |
