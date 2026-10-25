# corp_mock – PostgreSQL package (from fake_corporate_database v1.3)

Files
- `schema.sql`   tables, constraints, indexes, and four views (`vw_employee_detail`, `vw_departments`, `vw_positions`, `vw_locations`)
- `*.csv`        six value-only tables (lowercase snake_case headers, ISO dates, empty = NULL)
- `load.sql`     loads the CSVs in one transaction (self-referencing FKs are deferred)
- `comments.sql` stores table/column descriptions in the database (`\d+ employees` to see them)
- `verify.sql`   PASS/FAIL checks against the workbook's numbers
- `load.sh`      does it all: create DB (if missing) -> schema -> load -> comments -> verify

Run on the Pi (from this folder):
    ./load.sh            # database name defaults to corp_mock
    ./load.sh other_db   # or pick a name

Notes
- Re-running is safe: schema.sql drops and recreates the tables and views.
- Not exported on purpose: HEADCOUNT, EMPLOYEE_COUNT, ACTIVE_COUNT (now views) and EMPLOYMENT_STATE (generated column).
- For Power BI use the `vw_` views; they expose the original workbook column names (e.g. "EMPLOYEE_ID").
