-- Verification: every row should say PASS. Expected values come from the workbook (v1.3).
\pset pager off
WITH checks(check_name, expected, actual) AS (
  VALUES
  ('rows: departments',       15,   (SELECT count(*) FROM departments)),
  ('rows: locations',         12,   (SELECT count(*) FROM locations)),
  ('rows: positions',         118,  (SELECT count(*) FROM positions)),
  ('rows: employees',         1513, (SELECT count(*) FROM employees)),
  ('rows: employee_history',  1513, (SELECT count(*) FROM employee_history)),
  ('rows: compensation',      1513, (SELECT count(*) FROM compensation)),
  ('active employees',        1200, (SELECT count(*) FROM employee_history WHERE employment_state='Active')),
  ('terminated employees',    313,  (SELECT count(*) FROM employee_history WHERE employment_state='Terminated')),
  ('employees without a manager (CEO only)', 1, (SELECT count(*) FROM employees WHERE mgr_id IS NULL)),
  ('departments without a parent (root only)', 1, (SELECT count(*) FROM departments WHERE parent_department_id IS NULL)),
  ('active employees with a terminated manager', 0,
     (SELECT count(*) FROM employees e JOIN employee_history h ON h.employee_id=e.employee_id
        JOIN employee_history mh ON mh.employee_id=e.mgr_id
       WHERE h.employment_state='Active' AND mh.employment_state='Terminated')),
  ('reports whose manager has a lower or equal job level', 0,
     (SELECT count(*) FROM employees e JOIN positions p ON p.position_id=e.position_id
        JOIN employees m ON m.employee_id=e.mgr_id JOIN positions mp ON mp.position_id=m.position_id
       WHERE mp.job_level <= p.job_level)),
  ('hired before department founded', 0,
     (SELECT count(*) FROM employee_history h JOIN departments d USING (department_id) WHERE h.hire_date < d.founding_date)),
  ('under 18 at hire', 0,
     (SELECT count(*) FROM employees e JOIN employee_history h USING (employee_id) WHERE h.hire_date < e.date_of_birth + interval '18 years')),
  ('sum of department headcount = active', 1200, (SELECT sum("HEADCOUNT") FROM vw_departments)),
  ('sum of position employee counts', 1513, (SELECT sum("EMPLOYEE_COUNT") FROM vw_positions)),
  ('sum of location employee counts', 1513, (SELECT sum("EMPLOYEE_COUNT") FROM vw_locations)),
  ('sum of location active counts',   1200, (SELECT sum("ACTIVE_COUNT") FROM vw_locations)),
  ('headcount: Manufacturing (200)', 480, (SELECT "HEADCOUNT" FROM vw_departments WHERE "DEPARTMENT_ID"=200)),
  ('headcount: Marketing (800)',      35, (SELECT "HEADCOUNT" FROM vw_departments WHERE "DEPARTMENT_ID"=800)),
  ('headcount: Legal (1400)',         12, (SELECT "HEADCOUNT" FROM vw_departments WHERE "DEPARTMENT_ID"=1400)),
  ('active at HQ',                   275, (SELECT "ACTIVE_COUNT" FROM vw_locations WHERE "LOCATION_NAME"='HQ')),
  ('active at Dayton',               306, (SELECT "ACTIVE_COUNT" FROM vw_locations WHERE "LOCATION_NAME"='Dayton')),
  ('VP of Marketing reports to Chief Revenue Officer', 1,
     (SELECT count(*) FROM vw_employee_detail v JOIN employees m ON m.employee_id=v."MGR_ID"
        JOIN positions mp ON mp.position_id=m.position_id
       WHERE v."POSITION"='VP of Marketing' AND mp.position_title='Chief Revenue Officer')),
  ('total salary (whole USD)', 90746500, (SELECT sum(salary) FROM compensation))
)
SELECT check_name, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks;
