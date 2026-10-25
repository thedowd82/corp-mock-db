-- corp_mock schema for PostgreSQL 12+ (built/tested for 16)
-- Run inside the corp_mock database. Safe to re-run: drops and recreates everything.
\set ON_ERROR_STOP on
SET client_min_messages = warning;  -- hide "does not exist, skipping" notices on first run

DROP VIEW  IF EXISTS vw_employee_detail, vw_departments, vw_positions, vw_locations;
DROP TABLE IF EXISTS compensation, employee_history, employees, positions, locations, departments CASCADE;

CREATE TABLE departments (
    department_id         integer      PRIMARY KEY,
    department_name       varchar(100) NOT NULL UNIQUE,
    budget_2025           integer      NOT NULL CHECK (budget_2025 >= 0),
    budget_2026           integer      NOT NULL CHECK (budget_2026 >= 0),
    budget_2027           integer      NOT NULL CHECK (budget_2027 >= 0),
    founding_date         date         NOT NULL,
    parent_department_id  integer      NULL
        REFERENCES departments (department_id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE locations (
    location_id    integer     PRIMARY KEY,
    location_name  varchar(50) NOT NULL UNIQUE,
    location_type  varchar(10) NOT NULL
);

CREATE TABLE positions (
    position_id     integer      PRIMARY KEY,
    position_title  varchar(100) NOT NULL UNIQUE,
    job_level       smallint     NOT NULL CHECK (job_level BETWEEN 1 AND 10)
);

CREATE TABLE employees (
    employee_id     integer      PRIMARY KEY,
    employee_first  varchar(50)  NOT NULL,
    employee_last   varchar(50)  NOT NULL,
    date_of_birth   date         NOT NULL,
    email           varchar(100) NOT NULL UNIQUE,
    mgr_id          integer      NULL
        REFERENCES employees (employee_id) DEFERRABLE INITIALLY DEFERRED,
    position_id     integer      NOT NULL REFERENCES positions (position_id),
    location_id     integer      NOT NULL REFERENCES locations (location_id),
    CHECK (mgr_id IS NULL OR mgr_id <> employee_id)
);

-- One row per employee for now (primary key = employee_id).
CREATE TABLE employee_history (
    employee_id      integer     PRIMARY KEY REFERENCES employees (employee_id),
    department_id    integer     NOT NULL REFERENCES departments (department_id),
    hire_date        date        NOT NULL,
    term_date        date        NULL,
    employment_type  varchar(20) NOT NULL
        CHECK (employment_type IN ('Full-Time', 'Part-Time', 'Contractor')),
    -- Derived from term_date; replaces the Excel formula column.
    employment_state varchar(10) GENERATED ALWAYS AS
        (CASE WHEN term_date IS NULL THEN 'Active' ELSE 'Terminated' END) STORED,
    CHECK (term_date IS NULL OR term_date >= hire_date)
);

CREATE TABLE compensation (
    employee_id  integer  PRIMARY KEY REFERENCES employees (employee_id),
    salary       integer  NOT NULL CHECK (salary > 0),   -- annual, whole USD
    perf_rating  smallint NOT NULL CHECK (perf_rating BETWEEN 1 AND 5)
);

CREATE INDEX ix_employees_mgr      ON employees (mgr_id);
CREATE INDEX ix_employees_position ON employees (position_id);
CREATE INDEX ix_employees_location ON employees (location_id);
CREATE INDEX ix_history_department ON employee_history (department_id);

-- ---------------------------------------------------------------------------
-- Views: original workbook column names (quoted, uppercase) for Power BI.
-- Derived counts live here instead of being stored.
-- ---------------------------------------------------------------------------
CREATE VIEW vw_employee_detail AS
SELECT e.employee_id      AS "EMPLOYEE_ID",
       e.employee_first   AS "EMPLOYEE_FIRST",
       e.employee_last    AS "EMPLOYEE_LAST",
       e.date_of_birth    AS "DATE_OF_BIRTH",
       e.email            AS "EMAIL",
       e.mgr_id           AS "MGR_ID",
       m.employee_first || ' ' || m.employee_last AS "MANAGER_NAME",
       p.position_title   AS "POSITION",
       p.job_level        AS "JOB_LEVEL",
       l.location_name    AS "LOCATION",
       l.location_type    AS "LOCATION_TYPE",
       h.department_id    AS "DEPARTMENT_ID",
       d.department_name  AS "DEPARTMENT_NAME",
       h.hire_date        AS "HIRE_DATE",
       h.term_date        AS "TERM_DATE",
       h.employment_type  AS "EMPLOYMENT_TYPE",
       h.employment_state AS "EMPLOYMENT_STATE",
       c.salary           AS "SALARY",
       c.perf_rating      AS "PERF_RATING"
FROM employees e
JOIN positions        p ON p.position_id   = e.position_id
JOIN locations        l ON l.location_id   = e.location_id
JOIN employee_history h ON h.employee_id   = e.employee_id
JOIN departments      d ON d.department_id = h.department_id
JOIN compensation     c ON c.employee_id   = e.employee_id
LEFT JOIN employees   m ON m.employee_id   = e.mgr_id;

CREATE VIEW vw_departments AS
SELECT d.department_id        AS "DEPARTMENT_ID",
       d.department_name      AS "DEPARTMENT_NAME",
       d.budget_2025          AS "BUDGET_2025",
       d.budget_2026          AS "BUDGET_2026",
       d.budget_2027          AS "BUDGET_2027",
       d.founding_date        AS "FOUNDING_DATE",
       d.parent_department_id AS "PARENT_DEPARTMENT_ID",
       pd.department_name     AS "PARENT_DEPARTMENT_NAME",
       count(h.employee_id) FILTER (WHERE h.employment_state = 'Active') AS "HEADCOUNT"
FROM departments d
LEFT JOIN departments pd ON pd.department_id = d.parent_department_id
LEFT JOIN employee_history h ON h.department_id = d.department_id
GROUP BY d.department_id, pd.department_name;

CREATE VIEW vw_positions AS
SELECT p.position_id    AS "POSITION_ID",
       p.position_title AS "POSITION_TITLE",
       p.job_level      AS "JOB_LEVEL",
       count(e.employee_id) AS "EMPLOYEE_COUNT",
       count(e.employee_id) FILTER (WHERE h.employment_state = 'Active') AS "ACTIVE_COUNT"
FROM positions p
LEFT JOIN employees e ON e.position_id = p.position_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY p.position_id;

CREATE VIEW vw_locations AS
SELECT l.location_id    AS "LOCATION_ID",
       l.location_name  AS "LOCATION_NAME",
       l.location_type  AS "LOCATION_TYPE",
       count(e.employee_id) AS "EMPLOYEE_COUNT",
       count(e.employee_id) FILTER (WHERE h.employment_state = 'Active') AS "ACTIVE_COUNT"
FROM locations l
LEFT JOIN employees e ON e.location_id = l.location_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY l.location_id;
