#!/usr/bin/env bash
# Usage: ./load.sh [database_name]     (default: corp_mock)
# Connects as the current user (or whatever PGUSER/PGHOST/PGPORT/PGPASSWORD say).
# Creates the database if missing, rebuilds the schema, loads the CSVs, runs verification.
set -euo pipefail
cd "$(dirname "$0")"
DB="${1:-corp_mock}"

if ! psql -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '${DB}'" | grep -q 1; then
  echo "Creating database ${DB}..."
  createdb "${DB}"
fi

echo "Building schema..."
psql -d "${DB}" -q -v ON_ERROR_STOP=1 -f schema.sql
echo "Loading data..."
psql -d "${DB}" -q -v ON_ERROR_STOP=1 -f load.sql
echo "Adding table/column descriptions..."
psql -d "${DB}" -q -v ON_ERROR_STOP=1 -f comments.sql
echo "Verifying..."
psql -d "${DB}" -f verify.sql
