# corp_mock - Oracle package (from fake_corporate_database v1.3)

Built and tested on Oracle AI Database Free 23.26 (the same image as the dblab-oracle container).

Files
- `create_schema.sql`  run once as SYSDBA: creates the CORP_MOCK schema (Oracle's equivalent of a database) and a read-only directory object for the CSVs
- `schema.sql`         tables (deferrable self-referencing FKs, virtual column employment_state), indexes, and four views (`vw_employee_detail`, `vw_departments`, `vw_positions`, `vw_locations`)
- `*.csv`              six value-only tables (same files as the other packages)
- `load.sql`           loads the CSVs through temporary external tables, then one `INSERT ... SELECT` per table in a single transaction; foreign keys are checked at COMMIT
- `comments.sql`       table/view/column descriptions (`COMMENT ON`)
- `verify.sql`         34 PASS/FAIL checks (25 workbook checks, 2 constraint-validation checks, 7 orphan checks)
- `run_all.sql`        schema -> load -> comments -> verify in one SQL*Plus session
- `load.ps1`           PowerShell runner for the Docker container

Run (PowerShell on the Windows machine):
1. Unzip so the folder is `C:\Users\thedo\Documents\db-lab\init\oracle\corp_mock_oracle`
   (inside the container: `/opt/oracle/scripts/setup/corp_mock_oracle`; the container only auto-runs files at the top level of that mount, so this subfolder is ignored at startup).
2. `cd` into that folder and run `.\load.ps1`
   Options: `-SchemaPassword` (default `Corp_Mock_2026`; letters, digits, underscore), `-Container`, `-ContainerDir`.

Connect afterwards
- Inside the container: `sqlplus corp_mock/<password>@//localhost:1521/FREEPDB1`
- From Windows tools: host `localhost`, port 1521, service name `FREEPDB1`, user `CORP_MOCK`.
- Power BI needs Oracle client drivers (ODAC / Oracle Instant Client) installed on Windows first.

Notes
- Re-running is safe: schema.sql drops and recreates the tables and views, and the schema password is reset to the one supplied.
- The admin work uses OS authentication inside the container (`/ as sysdba`), so no admin password is typed or stored.
- Not exported on purpose: HEADCOUNT, EMPLOYEE_COUNT, ACTIVE_COUNT (views) and EMPLOYMENT_STATE (virtual column).
