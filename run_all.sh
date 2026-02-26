#!/usr/bin/env bash
# ============================================================
# run_all.sh — Spin up PostgreSQL and execute all SQL scripts
# ============================================================
set -euo pipefail

DB_CONTAINER="ats_dwh"
DB_NAME="ats"
DB_USER="ats_user"

PSQL="docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME"

echo "==> Starting PostgreSQL container..."
docker compose up -d --wait
echo "    Container is healthy."

# Files 00, 01, 03 run automatically via docker-entrypoint-initdb.d
# Files 02, 04, 05 are analytical queries — we run them explicitly.

echo ""
echo "=========================================="
echo " Data Quality Checks (02)"
echo "=========================================="
$PSQL -f /sql/02_data_quality_checks.sql

echo ""
echo "=========================================="
echo " Data Mart: dm_hiring_process (03)"
echo "=========================================="
$PSQL -c "SELECT * FROM dm_hiring_process ORDER BY app_id;"

echo ""
echo "=========================================="
echo " Monthly Active Pipeline (04)"
echo "=========================================="
$PSQL -f /sql/04_monthly_active_pipeline.sql

echo ""
echo "=========================================="
echo " Cumulative Hires by Source (05)"
echo "=========================================="
$PSQL -f /sql/05_cumulative_hires_by_source.sql

echo ""
echo "=== All scripts executed successfully ==="
echo ""
echo "To connect manually:"
echo "  docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME"
