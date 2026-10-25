-- Loads the CSVs in this folder (paths are relative to where the client is run).
-- MariaDB cannot defer foreign keys, so checks are off during the load; verify.sql
-- re-checks every relationship for orphans. Empty CSV fields become NULL.
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

LOAD DATA LOCAL INFILE 'departments.csv' INTO TABLE departments CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (department_id, department_name, budget_2025, budget_2026, budget_2027, founding_date, @parent)
  SET parent_department_id = NULLIF(TRIM(TRAILING '\r' FROM @parent), '');

LOAD DATA LOCAL INFILE 'locations.csv' INTO TABLE locations CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (location_id, location_name, @type)
  SET location_type = TRIM(TRAILING '\r' FROM @type);

LOAD DATA LOCAL INFILE 'positions.csv' INTO TABLE positions CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (position_id, position_title, @lvl)
  SET job_level = TRIM(TRAILING '\r' FROM @lvl);

LOAD DATA LOCAL INFILE 'employees.csv' INTO TABLE employees CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (employee_id, employee_first, employee_last, date_of_birth, email, @mgr, position_id, @loc)
  SET mgr_id = NULLIF(@mgr, ''), location_id = TRIM(TRAILING '\r' FROM @loc);

LOAD DATA LOCAL INFILE 'employee_history.csv' INTO TABLE employee_history CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (employee_id, department_id, hire_date, @term, @etype)
  SET term_date = NULLIF(@term, ''), employment_type = TRIM(TRAILING '\r' FROM @etype);

LOAD DATA LOCAL INFILE 'compensation.csv' INTO TABLE compensation CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (employee_id, salary, @rating)
  SET perf_rating = TRIM(TRAILING '\r' FROM @rating);

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
