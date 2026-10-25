#!/usr/bin/env bash
# Usage: ./load.sh [database_name]     (default: corp_mock)
# Runs as root through the unix socket (sudo mariadb), the default MariaDB setup on Ubuntu.
# To use another account instead:  MARIADB_CMD="mariadb -u youruser -p" ./load.sh
# Creates the database if missing, rebuilds the schema, loads the CSVs, runs verification.
set -euo pipefail
cd "$(dirname "$0")"
DB="${1:-corp_mock}"
if [ -n "${MARIADB_CMD:-}" ]; then MY="$MARIADB_CMD"
elif [ "$(id -u)" -eq 0 ]; then MY="mariadb"
else MY="sudo mariadb"; fi

echo "Preparing database ${DB}..."
# local_infile lets the client send the CSV files; this server setting reverts at the next restart.
$MY -e "CREATE DATABASE IF NOT EXISTS \`${DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; SET GLOBAL local_infile = 1;"

echo "Building schema, loading data, verifying..."
$MY --local-infile=1 --table "${DB}" < run_all.sql
