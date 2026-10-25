-- corp_mock schema for MariaDB 10.2+ (built/tested for 10.11)
-- Run inside the corp_mock database. Safe to re-run: drops and recreates everything.
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW  IF EXISTS vw_employee_detail, vw_departments, vw_positions, vw_locations;
DROP TABLE IF EXISTS compensation, employee_history, employees, positions, locations, departments;

CREATE TABLE departments (
    department_id         INT          NOT NULL COMMENT 'Department ID (PK).',
    department_name       VARCHAR(100) NOT NULL COMMENT 'Department name; unique.',
    budget_2025           INT          NOT NULL COMMENT '2025 budget, whole USD (not thousands or millions).',
    budget_2026           INT          NOT NULL COMMENT '2026 budget, whole USD.',
    budget_2027           INT          NOT NULL COMMENT '2027 budget, whole USD. Facilities dips versus 2026 (remodel-style anomaly, intentional).',
    founding_date         DATE         NOT NULL COMMENT 'Date the department was founded; no employee is hired before this.',
    parent_department_id  INT          NULL     COMMENT 'Parent department; NULL only for the root (Executive).',
    PRIMARY KEY (department_id),
    UNIQUE KEY uq_departments_name (department_name),
    CONSTRAINT fk_departments_parent FOREIGN KEY (parent_department_id) REFERENCES departments (department_id),
    CONSTRAINT ck_departments_budget CHECK (budget_2025 >= 0 AND budget_2026 >= 0 AND budget_2027 >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Org departments (15). Self-referencing hierarchy via parent_department_id; Executive is the root. Budgets are whole USD.';

CREATE TABLE locations (
    location_id    INT         NOT NULL COMMENT 'Location ID (PK).',
    location_name  VARCHAR(50) NOT NULL COMMENT 'Location name; unique.',
    location_type  VARCHAR(10) NOT NULL COMMENT 'HQ, Site (a named city other than HQ) or Remote.',
    PRIMARY KEY (location_id),
    UNIQUE KEY uq_locations_name (location_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Work locations (12): HQ, named city sites, and Remote.';

CREATE TABLE positions (
    position_id     INT          NOT NULL COMMENT 'Position ID (PK).',
    position_title  VARCHAR(100) NOT NULL COMMENT 'Job title; unique.',
    job_level       SMALLINT     NOT NULL COMMENT 'Job level 1-10 (10 = CEO). Single source of truth for level; each title has exactly one. Was LEVEL in the workbook (renamed: Oracle reserved word).',
    PRIMARY KEY (position_id),
    UNIQUE KEY uq_positions_title (position_title),
    CONSTRAINT ck_positions_level CHECK (job_level BETWEEN 1 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Job titles lookup (118), one row per title, with its job level.';

CREATE TABLE employees (
    employee_id     INT          NOT NULL COMMENT 'Employee ID (PK).',
    employee_first  VARCHAR(50)  NOT NULL COMMENT 'First name.',
    employee_last   VARCHAR(50)  NOT NULL COMMENT 'Last name.',
    date_of_birth   DATE         NOT NULL COMMENT 'Date of birth; employees are 18+ at hire.',
    email           VARCHAR(100) NOT NULL COMMENT 'first.last@ourbusiness.biz, lower case; unique.',
    mgr_id          INT          NULL     COMMENT 'Current manager (employees.employee_id); NULL only for the CEO. Managers always have a higher job level than their reports.',
    position_id     INT          NOT NULL COMMENT 'FK to positions; join for job title and level.',
    location_id     INT          NOT NULL COMMENT 'FK to locations; join for location name.',
    PRIMARY KEY (employee_id),
    UNIQUE KEY uq_employees_email (email),
    CONSTRAINT fk_employees_mgr      FOREIGN KEY (mgr_id)      REFERENCES employees (employee_id),
    CONSTRAINT fk_employees_position FOREIGN KEY (position_id) REFERENCES positions (position_id),
    CONSTRAINT fk_employees_location FOREIGN KEY (location_id) REFERENCES locations (location_id),
    CONSTRAINT ck_employees_not_own_mgr CHECK (mgr_id IS NULL OR mgr_id <> employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One row per employee (1,513, including terminated). Current manager only; no manager history.';

-- One row per employee for now (primary key = employee_id).
CREATE TABLE employee_history (
    employee_id      INT         NOT NULL COMMENT 'Employee (PK, FK to employees).',
    department_id    INT         NOT NULL COMMENT 'Department the employee belongs to.',
    hire_date        DATE        NOT NULL COMMENT 'Hire date; on or after the department founding date.',
    term_date        DATE        NULL     COMMENT 'Termination date; NULL = still employed. Must not precede hire_date.',
    employment_type  VARCHAR(20) NOT NULL COMMENT 'Full-Time, Part-Time or Contractor. Does not indicate terminations; use employment_state. Was STATUS in the workbook.',
    -- Derived from term_date; replaces the Excel formula column.
    employment_state VARCHAR(10) GENERATED ALWAYS AS
        (CASE WHEN term_date IS NULL THEN 'Active' ELSE 'Terminated' END) STORED
        COMMENT 'Generated: Active when term_date is NULL, otherwise Terminated.',
    PRIMARY KEY (employee_id),
    CONSTRAINT fk_history_employee   FOREIGN KEY (employee_id)   REFERENCES employees (employee_id),
    CONSTRAINT fk_history_department FOREIGN KEY (department_id) REFERENCES departments (department_id),
    CONSTRAINT ck_history_type  CHECK (employment_type IN ('Full-Time', 'Part-Time', 'Contractor')),
    CONSTRAINT ck_history_dates CHECK (term_date IS NULL OR term_date >= hire_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employment dates, department and type. One row per employee today; use effective-dated rows if true history is ever needed.';

CREATE TABLE compensation (
    employee_id  INT      NOT NULL COMMENT 'Employee (PK, FK to employees).',
    salary       INT      NOT NULL COMMENT 'Annual salary in whole USD (not thousands); must be > 0.',
    perf_rating  SMALLINT NOT NULL COMMENT 'Performance rating 1-5.',
    PRIMARY KEY (employee_id),
    CONSTRAINT fk_compensation_employee FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
    CONSTRAINT ck_compensation_salary CHECK (salary > 0),
    CONSTRAINT ck_compensation_rating CHECK (perf_rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Annual salary (whole USD) and latest performance rating. One row per employee; no effective date.';

-- ---------------------------------------------------------------------------
-- Views: original workbook column names (uppercase) for Power BI.
-- Derived counts live here instead of being stored.
-- ---------------------------------------------------------------------------
CREATE VIEW vw_employee_detail AS
SELECT e.employee_id      AS `EMPLOYEE_ID`,
       e.employee_first   AS `EMPLOYEE_FIRST`,
       e.employee_last    AS `EMPLOYEE_LAST`,
       e.date_of_birth    AS `DATE_OF_BIRTH`,
       e.email            AS `EMAIL`,
       e.mgr_id           AS `MGR_ID`,
       CONCAT(m.employee_first, ' ', m.employee_last) AS `MANAGER_NAME`,
       p.position_title   AS `POSITION`,
       p.job_level        AS `JOB_LEVEL`,
       l.location_name    AS `LOCATION`,
       l.location_type    AS `LOCATION_TYPE`,
       h.department_id    AS `DEPARTMENT_ID`,
       d.department_name  AS `DEPARTMENT_NAME`,
       h.hire_date        AS `HIRE_DATE`,
       h.term_date        AS `TERM_DATE`,
       h.employment_type  AS `EMPLOYMENT_TYPE`,
       h.employment_state AS `EMPLOYMENT_STATE`,
       c.salary           AS `SALARY`,
       c.perf_rating      AS `PERF_RATING`
FROM employees e
JOIN positions        p ON p.position_id   = e.position_id
JOIN locations        l ON l.location_id   = e.location_id
JOIN employee_history h ON h.employee_id   = e.employee_id
JOIN departments      d ON d.department_id = h.department_id
JOIN compensation     c ON c.employee_id   = e.employee_id
LEFT JOIN employees   m ON m.employee_id   = e.mgr_id;

CREATE VIEW vw_departments AS
SELECT d.department_id        AS `DEPARTMENT_ID`,
       d.department_name      AS `DEPARTMENT_NAME`,
       d.budget_2025          AS `BUDGET_2025`,
       d.budget_2026          AS `BUDGET_2026`,
       d.budget_2027          AS `BUDGET_2027`,
       d.founding_date        AS `FOUNDING_DATE`,
       d.parent_department_id AS `PARENT_DEPARTMENT_ID`,
       pd.department_name     AS `PARENT_DEPARTMENT_NAME`,
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS `HEADCOUNT`
FROM departments d
LEFT JOIN departments pd ON pd.department_id = d.parent_department_id
LEFT JOIN employee_history h ON h.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget_2025, d.budget_2026, d.budget_2027,
         d.founding_date, d.parent_department_id, pd.department_name;

CREATE VIEW vw_positions AS
SELECT p.position_id    AS `POSITION_ID`,
       p.position_title AS `POSITION_TITLE`,
       p.job_level      AS `JOB_LEVEL`,
       COUNT(e.employee_id) AS `EMPLOYEE_COUNT`,
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS `ACTIVE_COUNT`
FROM positions p
LEFT JOIN employees e ON e.position_id = p.position_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY p.position_id, p.position_title, p.job_level;

CREATE VIEW vw_locations AS
SELECT l.location_id    AS `LOCATION_ID`,
       l.location_name  AS `LOCATION_NAME`,
       l.location_type  AS `LOCATION_TYPE`,
       COUNT(e.employee_id) AS `EMPLOYEE_COUNT`,
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS `ACTIVE_COUNT`
FROM locations l
LEFT JOIN employees e ON e.location_id = l.location_id
LEFT JOIN employee_history h ON h.employee_id = e.employee_id
GROUP BY l.location_id, l.location_name, l.location_type;

SET FOREIGN_KEY_CHECKS = 1;
