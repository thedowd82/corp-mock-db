-- Loads the CSVs in this folder. Run from this folder (paths are relative to psql's cwd).
-- Self-referencing FKs are deferred, so everything loads in one transaction and is checked at COMMIT.
\set ON_ERROR_STOP on
BEGIN;
\copy departments      FROM 'departments.csv'      WITH (FORMAT csv, HEADER true)
\copy locations        FROM 'locations.csv'        WITH (FORMAT csv, HEADER true)
\copy positions        FROM 'positions.csv'        WITH (FORMAT csv, HEADER true)
\copy employees        FROM 'employees.csv'        WITH (FORMAT csv, HEADER true)
\copy employee_history (employee_id, department_id, hire_date, term_date, employment_type) FROM 'employee_history.csv' WITH (FORMAT csv, HEADER true)
\copy compensation     FROM 'compensation.csv'     WITH (FORMAT csv, HEADER true)
COMMIT;
