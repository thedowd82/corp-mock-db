-- Loads the CSVs through temporary external tables (directory CORP_MOCK_DIR), in ONE transaction.
-- The self-referencing foreign keys are DEFERRABLE INITIALLY DEFERRED, so they are checked at COMMIT.
-- Empty CSV fields become NULL (Oracle treats an empty string as NULL).
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET FEEDBACK OFF

CREATE TABLE ext_departments (
    department_id VARCHAR2(200),
    department_name VARCHAR2(200),
    budget_2025 VARCHAR2(200),
    budget_2026 VARCHAR2(200),
    budget_2027 VARCHAR2(200),
    founding_date VARCHAR2(200),
    parent_department_id VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('departments.csv')
) REJECT LIMIT 0;

CREATE TABLE ext_locations (
    location_id VARCHAR2(200),
    location_name VARCHAR2(200),
    location_type VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('locations.csv')
) REJECT LIMIT 0;

CREATE TABLE ext_positions (
    position_id VARCHAR2(200),
    position_title VARCHAR2(200),
    job_level VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('positions.csv')
) REJECT LIMIT 0;

CREATE TABLE ext_employees (
    employee_id VARCHAR2(200),
    employee_first VARCHAR2(200),
    employee_last VARCHAR2(200),
    date_of_birth VARCHAR2(200),
    email VARCHAR2(200),
    mgr_id VARCHAR2(200),
    position_id VARCHAR2(200),
    location_id VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('employees.csv')
) REJECT LIMIT 0;

CREATE TABLE ext_employee_history (
    employee_id VARCHAR2(200),
    department_id VARCHAR2(200),
    hire_date VARCHAR2(200),
    term_date VARCHAR2(200),
    employment_type VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('employee_history.csv')
) REJECT LIMIT 0;

CREATE TABLE ext_compensation (
    employee_id VARCHAR2(200),
    salary VARCHAR2(200),
    perf_rating VARCHAR2(200)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY corp_mock_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE SKIP 1
    NOBADFILE NOLOGFILE NODISCARDFILE
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('compensation.csv')
) REJECT LIMIT 0;

INSERT INTO departments
SELECT TO_NUMBER(department_id), department_name, TO_NUMBER(budget_2025), TO_NUMBER(budget_2026), TO_NUMBER(budget_2027),
       TO_DATE(founding_date, 'YYYY-MM-DD'), TO_NUMBER(TRIM(CHR(13) FROM parent_department_id))
FROM ext_departments;

INSERT INTO locations
SELECT TO_NUMBER(location_id), location_name, TRIM(CHR(13) FROM location_type) FROM ext_locations;

INSERT INTO positions
SELECT TO_NUMBER(position_id), position_title, TO_NUMBER(TRIM(CHR(13) FROM job_level)) FROM ext_positions;

INSERT INTO employees
SELECT TO_NUMBER(employee_id), employee_first, employee_last, TO_DATE(date_of_birth, 'YYYY-MM-DD'), email,
       TO_NUMBER(mgr_id), TO_NUMBER(position_id), TO_NUMBER(TRIM(CHR(13) FROM location_id))
FROM ext_employees;

INSERT INTO employee_history (employee_id, department_id, hire_date, term_date, employment_type)
SELECT TO_NUMBER(employee_id), TO_NUMBER(department_id), TO_DATE(hire_date, 'YYYY-MM-DD'),
       TO_DATE(term_date, 'YYYY-MM-DD'), TRIM(CHR(13) FROM employment_type)
FROM ext_employee_history;

INSERT INTO compensation
SELECT TO_NUMBER(employee_id), TO_NUMBER(salary), TO_NUMBER(TRIM(CHR(13) FROM perf_rating)) FROM ext_compensation;

COMMIT;

DROP TABLE ext_departments PURGE;
DROP TABLE ext_locations PURGE;
DROP TABLE ext_positions PURGE;
DROP TABLE ext_employees PURGE;
DROP TABLE ext_employee_history PURGE;
DROP TABLE ext_compensation PURGE;
