# corp_mock – MariaDB package (from fake_corporate_database v1.3)

Built and tested on MariaDB 10.11 (Ubuntu 24.04).

Files
- `schema.sql`   tables (InnoDB, utf8mb4) with constraints, inline column descriptions, and four views (`vw_employee_detail`, `vw_departments`, `vw_positions`, `vw_locations`)
- `*.csv`        six value-only tables (same files as the Postgres package)
- `load.sql`     LOAD DATA LOCAL INFILE for each CSV, in one transaction; empty fields become NULL
- `verify.sql`   32 PASS/FAIL checks (the 25 workbook checks plus 7 foreign-key orphan checks)
- `run_all.sql`  runs schema -> load -> verify in a single client session
- `load.sh`      creates the database (if missing) and runs run_all.sql

Run on the Pi (from this folder):
    ./load.sh             # database name defaults to corp_mock; uses `sudo mariadb` (root via unix socket)
    ./load.sh other_db    # or pick a name
    MARIADB_CMD="mariadb -u youruser -p" ./load.sh    # use a different account

Notes
- Re-running is safe: schema.sql drops and recreates the tables and views.
- MariaDB cannot defer foreign keys, so the load runs with FOREIGN_KEY_CHECKS=0 and verify.sql re-checks every relationship.
- load.sh runs `SET GLOBAL local_infile = 1` so the CSVs can be sent from the client; that setting reverts at the next server restart.
- Not exported on purpose: HEADCOUNT, EMPLOYEE_COUNT, ACTIVE_COUNT (views) and EMPLOYMENT_STATE (stored generated column).
- Power BI needs a network-capable account (root via unix socket will not work remotely); create one when you get there.
