-- Loads the CSVs from $(DIR) (a path INSIDE the container/server, passed with sqlcmd -v DIR=...).
-- SQL Server cannot defer foreign keys, so constraints are disabled during the load and then
-- re-enabled WITH CHECK, which makes SQL Server validate every row (the script fails if any row is bad).
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

ALTER TABLE dbo.departments      NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.locations        NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.positions        NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.employees        NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.employee_history NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.compensation     NOCHECK CONSTRAINT ALL;

BULK INSERT dbo.departments FROM '$(DIR)/departments.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);
BULK INSERT dbo.locations   FROM '$(DIR)/locations.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);
BULK INSERT dbo.positions   FROM '$(DIR)/positions.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);
BULK INSERT dbo.employees   FROM '$(DIR)/employees.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);
BULK INSERT dbo.compensation FROM '$(DIR)/compensation.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);

-- employee_history has a computed column, so load through a staging table.
CREATE TABLE #stg_history (
    employee_id int NOT NULL, department_id int NOT NULL, hire_date date NOT NULL,
    term_date date NULL, employment_type varchar(20) NOT NULL);
BULK INSERT #stg_history FROM '$(DIR)/employee_history.csv'
  WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', KEEPNULLS);
INSERT dbo.employee_history (employee_id, department_id, hire_date, term_date, employment_type)
SELECT employee_id, department_id, hire_date, term_date, employment_type FROM #stg_history;
DROP TABLE #stg_history;

-- Re-enable and validate every existing row (WITH CHECK). BULK INSERT skips check
-- constraints, so this step is what actually validates the loaded data.
ALTER TABLE dbo.departments      WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.locations        WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.positions        WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.employees        WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.employee_history WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.compensation     WITH CHECK CHECK CONSTRAINT ALL;

COMMIT TRANSACTION;
GO
