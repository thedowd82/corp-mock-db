-- corp_mock schema for SQL Server 2017+ (built/tested on SQL Server 2022, Linux/Docker)
-- Run inside the corp_mock database with sqlcmd -I (QUOTED_IDENTIFIER ON). Safe to re-run.
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DROP VIEW  IF EXISTS dbo.vw_employee_detail;
DROP VIEW  IF EXISTS dbo.vw_departments;
DROP VIEW  IF EXISTS dbo.vw_positions;
DROP VIEW  IF EXISTS dbo.vw_locations;
DROP TABLE IF EXISTS dbo.compensation;
DROP TABLE IF EXISTS dbo.employee_history;
DROP TABLE IF EXISTS dbo.employees;
DROP TABLE IF EXISTS dbo.positions;
DROP TABLE IF EXISTS dbo.locations;
DROP TABLE IF EXISTS dbo.departments;
GO

CREATE TABLE dbo.departments (
    department_id         int          NOT NULL,
    department_name       varchar(100) NOT NULL,
    budget_2025           int          NOT NULL,
    budget_2026           int          NOT NULL,
    budget_2027           int          NOT NULL,
    founding_date         date         NOT NULL,
    parent_department_id  int          NULL,
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_departments_name UNIQUE (department_name),
    CONSTRAINT fk_departments_parent FOREIGN KEY (parent_department_id) REFERENCES dbo.departments (department_id),
    CONSTRAINT ck_departments_budget CHECK (budget_2025 >= 0 AND budget_2026 >= 0 AND budget_2027 >= 0)
);

CREATE TABLE dbo.locations (
    location_id    int         NOT NULL,
    location_name  varchar(50) NOT NULL,
    location_type  varchar(10) NOT NULL,
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_locations_name UNIQUE (location_name)
);

CREATE TABLE dbo.positions (
    position_id     int          NOT NULL,
    position_title  varchar(100) NOT NULL,
    job_level       smallint     NOT NULL,
    CONSTRAINT pk_positions PRIMARY KEY (position_id),
    CONSTRAINT uq_positions_title UNIQUE (position_title),
    CONSTRAINT ck_positions_level CHECK (job_level BETWEEN 1 AND 10)
);

CREATE TABLE dbo.employees (
    employee_id     int          NOT NULL,
    employee_first  varchar(50)  NOT NULL,
    employee_last   varchar(50)  NOT NULL,
    date_of_birth   date         NOT NULL,
    email           varchar(100) NOT NULL,
    mgr_id          int          NULL,
    position_id     int          NOT NULL,
    location_id     int          NOT NULL,
    CONSTRAINT pk_employees PRIMARY KEY (employee_id),
    CONSTRAINT uq_employees_email UNIQUE (email),
    CONSTRAINT fk_employees_mgr      FOREIGN KEY (mgr_id)      REFERENCES dbo.employees (employee_id),
    CONSTRAINT fk_employees_position FOREIGN KEY (position_id) REFERENCES dbo.positions (position_id),
    CONSTRAINT fk_employees_location FOREIGN KEY (location_id) REFERENCES dbo.locations (location_id),
    CONSTRAINT ck_employees_not_own_mgr CHECK (mgr_id IS NULL OR mgr_id <> employee_id)
);

-- One row per employee for now (primary key = employee_id).
CREATE TABLE dbo.employee_history (
    employee_id      int         NOT NULL,
    department_id    int         NOT NULL,
    hire_date        date        NOT NULL,
    term_date        date        NULL,
    employment_type  varchar(20) NOT NULL,
    -- Derived from term_date; replaces the Excel formula column.
    employment_state AS (CAST(CASE WHEN term_date IS NULL THEN 'Active' ELSE 'Terminated' END AS varchar(10))) PERSISTED,
    CONSTRAINT pk_employee_history PRIMARY KEY (employee_id),
    CONSTRAINT fk_history_employee   FOREIGN KEY (employee_id)   REFERENCES dbo.employees (employee_id),
    CONSTRAINT fk_history_department FOREIGN KEY (department_id) REFERENCES dbo.departments (department_id),
    CONSTRAINT ck_history_type  CHECK (employment_type IN ('Full-Time', 'Part-Time', 'Contractor')),
    CONSTRAINT ck_history_dates CHECK (term_date IS NULL OR term_date >= hire_date)
);

CREATE TABLE dbo.compensation (
    employee_id  int      NOT NULL,
    salary       int      NOT NULL,   -- annual, whole USD
    perf_rating  smallint NOT NULL,
    CONSTRAINT pk_compensation PRIMARY KEY (employee_id),
    CONSTRAINT fk_compensation_employee FOREIGN KEY (employee_id) REFERENCES dbo.employees (employee_id),
    CONSTRAINT ck_compensation_salary CHECK (salary > 0),
    CONSTRAINT ck_compensation_rating CHECK (perf_rating BETWEEN 1 AND 5)
);
GO

CREATE INDEX ix_employees_mgr      ON dbo.employees (mgr_id);
CREATE INDEX ix_employees_position ON dbo.employees (position_id);
CREATE INDEX ix_employees_location ON dbo.employees (location_id);
CREATE INDEX ix_history_department ON dbo.employee_history (department_id);
GO

-- ---------------------------------------------------------------------------
-- Views: original workbook column names (uppercase) for Power BI.
-- Derived counts live here instead of being stored.
-- ---------------------------------------------------------------------------
CREATE VIEW dbo.vw_employee_detail AS
SELECT e.employee_id      AS [EMPLOYEE_ID],
       e.employee_first   AS [EMPLOYEE_FIRST],
       e.employee_last    AS [EMPLOYEE_LAST],
       e.date_of_birth    AS [DATE_OF_BIRTH],
       e.email            AS [EMAIL],
       e.mgr_id           AS [MGR_ID],
       CONCAT(m.employee_first, ' ', m.employee_last) AS [MANAGER_NAME],
       p.position_title   AS [POSITION],
       p.job_level        AS [JOB_LEVEL],
       l.location_name    AS [LOCATION],
       l.location_type    AS [LOCATION_TYPE],
       h.department_id    AS [DEPARTMENT_ID],
       d.department_name  AS [DEPARTMENT_NAME],
       h.hire_date        AS [HIRE_DATE],
       h.term_date        AS [TERM_DATE],
       h.employment_type  AS [EMPLOYMENT_TYPE],
       h.employment_state AS [EMPLOYMENT_STATE],
       c.salary           AS [SALARY],
       c.perf_rating      AS [PERF_RATING]
FROM dbo.employees e
JOIN dbo.positions        p ON p.position_id   = e.position_id
JOIN dbo.locations        l ON l.location_id   = e.location_id
JOIN dbo.employee_history h ON h.employee_id   = e.employee_id
JOIN dbo.departments      d ON d.department_id = h.department_id
JOIN dbo.compensation     c ON c.employee_id   = e.employee_id
LEFT JOIN dbo.employees   m ON m.employee_id   = e.mgr_id;
GO

CREATE VIEW dbo.vw_departments AS
SELECT d.department_id        AS [DEPARTMENT_ID],
       d.department_name      AS [DEPARTMENT_NAME],
       d.budget_2025          AS [BUDGET_2025],
       d.budget_2026          AS [BUDGET_2026],
       d.budget_2027          AS [BUDGET_2027],
       d.founding_date        AS [FOUNDING_DATE],
       d.parent_department_id AS [PARENT_DEPARTMENT_ID],
       pd.department_name     AS [PARENT_DEPARTMENT_NAME],
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS [HEADCOUNT]
FROM dbo.departments d
LEFT JOIN dbo.departments pd ON pd.department_id = d.parent_department_id
LEFT JOIN dbo.employee_history h ON h.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget_2025, d.budget_2026, d.budget_2027,
         d.founding_date, d.parent_department_id, pd.department_name;
GO

CREATE VIEW dbo.vw_positions AS
SELECT p.position_id    AS [POSITION_ID],
       p.position_title AS [POSITION_TITLE],
       p.job_level      AS [JOB_LEVEL],
       COUNT(e.employee_id) AS [EMPLOYEE_COUNT],
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS [ACTIVE_COUNT]
FROM dbo.positions p
LEFT JOIN dbo.employees e ON e.position_id = p.position_id
LEFT JOIN dbo.employee_history h ON h.employee_id = e.employee_id
GROUP BY p.position_id, p.position_title, p.job_level;
GO

CREATE VIEW dbo.vw_locations AS
SELECT l.location_id    AS [LOCATION_ID],
       l.location_name  AS [LOCATION_NAME],
       l.location_type  AS [LOCATION_TYPE],
       COUNT(e.employee_id) AS [EMPLOYEE_COUNT],
       COUNT(CASE WHEN h.employment_state = 'Active' THEN 1 END) AS [ACTIVE_COUNT]
FROM dbo.locations l
LEFT JOIN dbo.employees e ON e.location_id = l.location_id
LEFT JOIN dbo.employee_history h ON h.employee_id = e.employee_id
GROUP BY l.location_id, l.location_name, l.location_type;
GO
