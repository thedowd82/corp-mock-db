# corp_mock - SQL Server package (from fake_corporate_database v1.3)

Built and tested on SQL Server 2022 (16.0.4305.5, Linux) - the same build as the dblab-sqlserver Docker container.

Files
- `create_db.sql`  creates the database if missing
- `schema.sql`     tables, constraints, indexes, and four views (`vw_employee_detail`, `vw_departments`, `vw_positions`, `vw_locations`)
- `*.csv`          six value-only tables (same files as the other packages)
- `load.sql`       BULK INSERT of each CSV in one transaction; constraints are disabled for the load and re-enabled WITH CHECK (SQL Server validates every row)
- `comments.sql`   table/column descriptions as MS_Description extended properties
- `verify.sql`     34 PASS/FAIL checks (25 workbook checks, 2 constraint-trust checks, 7 orphan checks)
- `run_all.sql`    schema -> load -> comments -> verify in one sqlcmd session
- `load.ps1`       PowerShell runner for the Docker container

Run (PowerShell on the Windows machine):
1. Unzip so the folder is `C:\Users\thedo\Documents\db-lab\init\sqlserver\corp_mock_mssql`
   (it appears in the container as `/init/corp_mock_mssql`).
2. `cd` into that folder and run `.\load.ps1`
   Options: `-Container`, `-Database` (default corp_mock), `-ContainerDir`.

Power BI: Get Data > SQL Server, server `localhost,1433`, database `corp_mock`, SQL login `sa`
(password is the container's MSSQL_SA_PASSWORD), trust the server certificate, then pick the `vw_` views.

Notes
- Re-running is safe: schema.sql drops and recreates the tables and views.
- Not exported on purpose: HEADCOUNT, EMPLOYEE_COUNT, ACTIVE_COUNT (views) and EMPLOYMENT_STATE (persisted computed column).
- BULK INSERT reads files from inside the container, which is why the package lives under the /init mount.
- BULK INSERT ignores check constraints; load.sql re-validates them explicitly.
