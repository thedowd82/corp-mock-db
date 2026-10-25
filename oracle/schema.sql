-- corp_mock schema for Oracle 19c+ (built/tested for Oracle Free 23). Run as CORP_MOCK. Safe to re-run.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET FEEDBACK OFF

DROP VIEW  IF EXISTS vw_employee_detail;
DROP VIEW  IF EXISTS vw_departments;
DROP VIEW  IF EXISTS vw_positions;
DROP VIEW  IF EXISTS vw_locations;
DROP TABLE IF EXISTS compensation      CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS employee_history  CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS employees         CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS positions         CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS locations         CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS departments       CASCADE CONSTRAINTS PURGE;

CREATE TABLE departments (
    department_id         NUMBER(10)    NOT NULL,
    department_name       VARCHAR2(100) NOT NULL,
    budget_2025           NUMBER(10)    NOT NULL,
    budget_2026           NUMBER(10)    NOT NULL,
    budget_2027           NUMBER(10)    NOT NULL,
    founding_date         DATE          NOT NULL,
    parent_department_id  NUMBER(10)    NULL,
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_departments_name UNIQUE (department_name),
    CONSTRAINT fk_departments_parent FOREIGN KEY (parent_department_id)
        REFERENCES departments (department_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT ck_departments_budget CHECK (budget_2025 >= 0 AND budget_2026 >= 0 AND budget_2027 >= 0)
);

CREATE TABLE locations (
    location_id    NUMBER(10)   NOT NULL,
    location_name  VARCHAR2(50) NOT NULL,
    location_type  VARCHAR2(10) NOT NULL,
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_locations_name UNIQUE (location_name)
);

CREATE TABLE positions (
    position_id     NUMBER(10)    NOT NULL,
    position_title  VARCHAR2(100) NOT NULL,
    job_level       NUMBER(2)     NOT NULL,
    CONSTRAINT pk_positions PRIMARY KEY (position_id),
    CONSTRAINT uq_positions_title UNIQUE (position_title),
    CONSTRAINT ck_positions_level CHECK (job_level BETWEEN 1 AND 10)
);

CREATE TABLE employees (
    employee_id     NUMBER(10)    NOT NULL,
    employee_first  VARCHAR2(50)  NOT NULL,
    employee_last   VARCHAR2(50)  NOT NULL,
    date_of_birth   DATE          NOT NULL,
    email           VARCHAR2(100) NOT NULL,
    mgr_id          NUMBER(10)    NULL,
    position_id     NUMBER(10)    NOT NULL,
    location_id     NUMBER(10)    NOT NULL,
    CONSTRAINT pk_employees PRIMARY KEY (employee_id),
    CONSTRAINT uq_employees_email UNIQUE (email),
    CONSTRAINT fk_employees_mgr FOREIGN KEY (mgr_id)
        REFERENCES employees (employee_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_employees_position FOREIGN KEY (position_id) REFERENCES positions (position_id),
    CONSTRAINT fk_employees_location FOREIGN KEY (location_id) REFERENCES locations (location_id),
    CONSTRAINT ck_employees_not_own_mgr CHECK (mgr_id IS NULL OR mgr_id <> employee_id)
);

-- One row per employee for now (primary key = employee_id).
CREATE TABLE employee_history (
    employee_id      NUMBER(10)   NOT NULL,
    department_id    NUMBER(10)   NOT NULL,
    hire_date        DATE         NOT NULL,
    term_date        DATE         NULL,
    employment_type  VARCHAR2(20) NOT NULL,
    -- Derived from term_date; replaces the Excel formula column (Oracle virtual column).
    employment_state VARCHAR2(10) GENERATED ALWAYS AS
        (CASE WHEN term_date IS NULL THEN 'Active' ELSE 'Terminated' END) VIRTUAL,
    CONSTRAINT pk_employee_history PRIMARY KEY (employee_id),
    CONSTRAINT fk_history_employee   FOREIGN KEY (employee_id)   REFERENCES employees (employee_id),
    CONSTRAINT fk_history_department FOREIGN KEY (department_id) REFERENCES departments (department_id),
    CONSTRAINT ck_history_type  CHECK (employment_type IN ('Full-Time', 'Part-Time', 'Contractor')),
    CONSTRAINT ck_history_dates CHECK (term_date IS NULL OR term_date >= hire_date)
);

CREATE TABLE compensation (
    employee_id  NUMBER(10) NOT NULL,   -- annual salary, whole USD
    salary       NUMBER(10) NOT NULL,
    perf_rating  NUMBER(1)  NOT NULL,
    CONSTRAINT pk_compensation PRIMARY KEY (employee_id),
    CONSTRAINT fk_compensation_employee FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
    CONSTRAINT ck_compensation_salary CHECK (salary > 0),
    CONSTRAINT ck_compensation_rating CHECK (perf_rating BETWEEN 1 AND 5)
);

-- Oracle does not index foreign keys automatically.
CREATE INDEX ix_employees_mgr      ON employees (mgr_id);
CREATE INDEX ix_employees_position ON employees (position_id);
CREATE INDEX ix_employees_location ON employees (location_id);
CREATE INDEX ix_history_department ON employee_history (department_id);

-- ---------------------------------------------------------------------------
-- Views: original workbook column names (uppercase) for BI tools.
-- Derived counts live here instead of being stored.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_employee_detail AS
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

CREATE OR REPLACE VIEW vw_departments AS
SELECT d.department_id        AS "DEPARTMENT_ID",
       d.department_name      AS "DEPARTMENT_NAME",
       d.budget_2025          AS "BUDGET_2025",
       d.budget_2026          AS "BUDGET_2026",
       d.budget_2027          AS "BUDGET_2027",
       d.founding_date        AS "FOUNDING_DATE",
       d.parent_department_id AS "PARENT_DEPARTMENT_ID",
       pd.department_name     AS "PARENT_DEPARTMENT_NAME",
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS "HEADCOUNT"
FROM departments d
LEFT JOIN departments pd ON pd.department_id = d.parent_department_id
LEFT JOIN employee_history h ON h.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget_2025, d.budget_2026, d.budget_2027,
         d.founding_date, d.parent_department_id, pd.department_name;

CREATE OR REPLACE VIEW vw_positions AS
SELECT p.position_id    AS "POSITION_ID",
       p.position_title AS "POSITION_TITLE",
       p.job_level      AS "JOB_LEVEL",
       COUNT(e.employee_id) AS "EMPLOYEE_COUNT",
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS "ACTIVE_COUNT"
FROM positions p
LEFT JOIN employees e ON e.position_id = p.position_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY p.position_id, p.position_title, p.job_level;

CREATE OR REPLACE VIEW vw_locations AS
SELECT l.location_id    AS "LOCATION_ID",
       l.location_name  AS "LOCATION_NAME",
       l.location_type  AS "LOCATION_TYPE",
       COUNT(e.employee_id) AS "EMPLOYEE_COUNT",
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS "ACTIVE_COUNT"
FROM locations l
LEFT JOIN employees e ON e.location_id = l.location_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY l.location_id, l.location_name, l.location_type;
