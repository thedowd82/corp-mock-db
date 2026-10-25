-- Verification: every row should say PASS. Expected values come from the workbook (v1.3).
-- The last block re-checks every foreign key, because the load ran with FK checks off.
SELECT check_name, expected, actual, IF(expected = actual, 'PASS', 'FAIL') AS status
FROM (
  SELECT 'rows: departments' AS check_name, 15 AS expected, (SELECT COUNT(*) FROM departments) AS actual
  UNION ALL SELECT 'rows: locations',        12,   (SELECT COUNT(*) FROM locations)
  UNION ALL SELECT 'rows: positions',        118,  (SELECT COUNT(*) FROM positions)
  UNION ALL SELECT 'rows: employees',        1513, (SELECT COUNT(*) FROM employees)
  UNION ALL SELECT 'rows: employee_history', 1513, (SELECT COUNT(*) FROM employee_history)
  UNION ALL SELECT 'rows: compensation',     1513, (SELECT COUNT(*) FROM compensation)
  UNION ALL SELECT 'active employees',       1200, (SELECT COUNT(*) FROM employee_history WHERE employment_state='Active')
  UNION ALL SELECT 'terminated employees',   313,  (SELECT COUNT(*) FROM employee_history WHERE employment_state='Terminated')
  UNION ALL SELECT 'employees without a manager (CEO only)', 1, (SELECT COUNT(*) FROM employees WHERE mgr_id IS NULL)
  UNION ALL SELECT 'departments without a parent (root only)', 1, (SELECT COUNT(*) FROM departments WHERE parent_department_id IS NULL)
  UNION ALL SELECT 'active employees with a terminated manager', 0,
     (SELECT COUNT(*) FROM employees e JOIN employee_history h ON h.employee_id=e.employee_id
        JOIN employee_history mh ON mh.employee_id=e.mgr_id
       WHERE h.employment_state='Active' AND mh.employment_state='Terminated')
  UNION ALL SELECT 'reports whose manager has a lower or equal job level', 0,
     (SELECT COUNT(*) FROM employees e JOIN positions p ON p.position_id=e.position_id
        JOIN employees m ON m.employee_id=e.mgr_id JOIN positions mp ON mp.position_id=m.position_id
       WHERE mp.job_level <= p.job_level)
  UNION ALL SELECT 'hired before department founded', 0,
     (SELECT COUNT(*) FROM employee_history h JOIN departments d ON d.department_id=h.department_id WHERE h.hire_date < d.founding_date)
  UNION ALL SELECT 'under 18 at hire', 0,
     (SELECT COUNT(*) FROM employees e JOIN employee_history h ON h.employee_id=e.employee_id
       WHERE h.hire_date < DATE_ADD(e.date_of_birth, INTERVAL 18 YEAR))
  UNION ALL SELECT 'sum of department headcount = active', 1200, (SELECT SUM(`HEADCOUNT`) FROM vw_departments)
  UNION ALL SELECT 'sum of position employee counts', 1513, (SELECT SUM(`EMPLOYEE_COUNT`) FROM vw_positions)
  UNION ALL SELECT 'sum of location employee counts', 1513, (SELECT SUM(`EMPLOYEE_COUNT`) FROM vw_locations)
  UNION ALL SELECT 'sum of location active counts',   1200, (SELECT SUM(`ACTIVE_COUNT`) FROM vw_locations)
  UNION ALL SELECT 'headcount: Manufacturing (200)', 480, (SELECT `HEADCOUNT` FROM vw_departments WHERE `DEPARTMENT_ID`=200)
  UNION ALL SELECT 'headcount: Marketing (800)',      35, (SELECT `HEADCOUNT` FROM vw_departments WHERE `DEPARTMENT_ID`=800)
  UNION ALL SELECT 'headcount: Legal (1400)',         12, (SELECT `HEADCOUNT` FROM vw_departments WHERE `DEPARTMENT_ID`=1400)
  UNION ALL SELECT 'active at HQ',                   275, (SELECT `ACTIVE_COUNT` FROM vw_locations WHERE `LOCATION_NAME`='HQ')
  UNION ALL SELECT 'active at Dayton',               306, (SELECT `ACTIVE_COUNT` FROM vw_locations WHERE `LOCATION_NAME`='Dayton')
  UNION ALL SELECT 'VP of Marketing reports to Chief Revenue Officer', 1,
     (SELECT COUNT(*) FROM vw_employee_detail v JOIN employees m ON m.employee_id=v.`MGR_ID`
        JOIN positions mp ON mp.position_id=m.position_id
       WHERE v.`POSITION`='VP of Marketing' AND mp.position_title='Chief Revenue Officer')
  UNION ALL SELECT 'total salary (whole USD)', 90746500, (SELECT SUM(salary) FROM compensation)
  -- foreign-key orphan checks (all should be 0)
  UNION ALL SELECT 'orphans: departments.parent_department_id', 0,
     (SELECT COUNT(*) FROM departments c LEFT JOIN departments p ON p.department_id=c.parent_department_id WHERE c.parent_department_id IS NOT NULL AND p.department_id IS NULL)
  UNION ALL SELECT 'orphans: employees.mgr_id', 0,
     (SELECT COUNT(*) FROM employees c LEFT JOIN employees p ON p.employee_id=c.mgr_id WHERE c.mgr_id IS NOT NULL AND p.employee_id IS NULL)
  UNION ALL SELECT 'orphans: employees.position_id', 0,
     (SELECT COUNT(*) FROM employees c LEFT JOIN positions p ON p.position_id=c.position_id WHERE p.position_id IS NULL)
  UNION ALL SELECT 'orphans: employees.location_id', 0,
     (SELECT COUNT(*) FROM employees c LEFT JOIN locations p ON p.location_id=c.location_id WHERE p.location_id IS NULL)
  UNION ALL SELECT 'orphans: employee_history.employee_id', 0,
     (SELECT COUNT(*) FROM employee_history c LEFT JOIN employees p ON p.employee_id=c.employee_id WHERE p.employee_id IS NULL)
  UNION ALL SELECT 'orphans: employee_history.department_id', 0,
     (SELECT COUNT(*) FROM employee_history c LEFT JOIN departments p ON p.department_id=c.department_id WHERE p.department_id IS NULL)
  UNION ALL SELECT 'orphans: compensation.employee_id', 0,
     (SELECT COUNT(*) FROM compensation c LEFT JOIN employees p ON p.employee_id=c.employee_id WHERE p.employee_id IS NULL)
) AS checks;
