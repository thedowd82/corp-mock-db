-- Table, view and column descriptions (USER_TAB_COMMENTS / USER_COL_COMMENTS). Safe to re-run.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET FEEDBACK OFF

COMMENT ON TABLE departments IS 'Org departments (15). Self-referencing hierarchy via parent_department_id; Executive is the root. Budgets are whole USD.';
COMMENT ON TABLE locations IS 'Work locations (12): HQ, named city sites, and Remote.';
COMMENT ON TABLE positions IS 'Job titles lookup (118), one row per title, with its job level.';
COMMENT ON TABLE employees IS 'One row per employee (1,513, including terminated). Current manager only; no manager history.';
COMMENT ON TABLE employee_history IS 'Employment dates, department and type. One row per employee today; use effective-dated rows if true history is ever needed.';
COMMENT ON TABLE compensation IS 'Annual salary (whole USD) and latest performance rating. One row per employee; no effective date.';
COMMENT ON TABLE vw_employee_detail IS 'Denormalized employee view with names joined in; original workbook column names. Use this for Power BI.';
COMMENT ON TABLE vw_departments IS 'Departments plus parent name and derived active HEADCOUNT.';
COMMENT ON TABLE vw_positions IS 'Positions plus derived EMPLOYEE_COUNT (ever) and ACTIVE_COUNT.';
COMMENT ON TABLE vw_locations IS 'Locations plus derived EMPLOYEE_COUNT (ever) and ACTIVE_COUNT.';

COMMENT ON COLUMN departments.department_id IS 'Department ID (PK).';
COMMENT ON COLUMN departments.department_name IS 'Department name; unique.';
COMMENT ON COLUMN departments.budget_2025 IS '2025 budget, whole USD (not thousands or millions).';
COMMENT ON COLUMN departments.budget_2026 IS '2026 budget, whole USD.';
COMMENT ON COLUMN departments.budget_2027 IS '2027 budget, whole USD. Facilities dips versus 2026 (remodel-style anomaly, intentional).';
COMMENT ON COLUMN departments.founding_date IS 'Date the department was founded; no employee is hired before this.';
COMMENT ON COLUMN departments.parent_department_id IS 'Parent department; NULL only for the root (Executive). Deferred FK.';
COMMENT ON COLUMN locations.location_id IS 'Location ID (PK).';
COMMENT ON COLUMN locations.location_name IS 'Location name; unique.';
COMMENT ON COLUMN locations.location_type IS 'HQ, Site (a named city other than HQ) or Remote.';
COMMENT ON COLUMN positions.position_id IS 'Position ID (PK).';
COMMENT ON COLUMN positions.position_title IS 'Job title; unique.';
COMMENT ON COLUMN positions.job_level IS 'Job level 1-10 (10 = CEO). Single source of truth for level; each title has exactly one. Was LEVEL in the workbook (renamed: Oracle reserved word).';
COMMENT ON COLUMN employees.employee_id IS 'Employee ID (PK).';
COMMENT ON COLUMN employees.employee_first IS 'First name.';
COMMENT ON COLUMN employees.employee_last IS 'Last name.';
COMMENT ON COLUMN employees.date_of_birth IS 'Date of birth; employees are 18+ at hire.';
COMMENT ON COLUMN employees.email IS 'first.last@ourbusiness.biz, lower case; unique.';
COMMENT ON COLUMN employees.mgr_id IS 'Current manager (employees.employee_id); NULL only for the CEO. Deferred FK. Managers always have a higher job level than their reports.';
COMMENT ON COLUMN employees.position_id IS 'FK to positions; join for job title and level.';
COMMENT ON COLUMN employees.location_id IS 'FK to locations; join for location name.';
COMMENT ON COLUMN employee_history.employee_id IS 'Employee (PK, FK to employees).';
COMMENT ON COLUMN employee_history.department_id IS 'Department the employee belongs to.';
COMMENT ON COLUMN employee_history.hire_date IS 'Hire date; on or after the department founding date.';
COMMENT ON COLUMN employee_history.term_date IS 'Termination date; NULL = still employed. Must not precede hire_date.';
COMMENT ON COLUMN employee_history.employment_type IS 'Full-Time, Part-Time or Contractor. Does not indicate terminations; use employment_state. Was STATUS in the workbook.';
COMMENT ON COLUMN employee_history.employment_state IS 'Generated: Active when term_date is NULL, otherwise Terminated.';
COMMENT ON COLUMN compensation.employee_id IS 'Employee (PK, FK to employees).';
COMMENT ON COLUMN compensation.salary IS 'Annual salary in whole USD (not thousands); must be > 0.';
COMMENT ON COLUMN compensation.perf_rating IS 'Performance rating 1-5.';
