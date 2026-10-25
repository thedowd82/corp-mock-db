# corp-mock-db

A fictional company's employee database (1,513 employees, 15 departments, 118 job titles, 12 locations),
built as a hands-on SQL project: one cleaned source workbook, one set of six CSVs, and the same schema
rebuilt and verified in **PostgreSQL, MariaDB, SQL Server and Oracle**. Every package loads the data in a
single transaction where the engine allows it, then runs a PASS/FAIL verification script against numbers
taken from the workbook. All data is fake.

## Status

| Engine | Folder | Runs on | Verification |
|---|---|---|---|
| PostgreSQL 16 | `postgres/` | Raspberry Pi 3 | 25 checks, all pass |
| MariaDB 10.11 | `mariadb/` | Raspberry Pi 3 | 32 checks (tested; Pi run pending) |
| SQL Server 2022 | `mssql/` | Docker (Windows host) | 34 checks, all pass |
| Oracle Free 23 | `oracle/` | Docker (Windows host) | 34 checks, all pass |

## Layout

```
data/        source workbooks (original v1.2 and cleaned v1.3, with Data Dictionary and Data Quality sheets)
postgres/    schema.sql, load.sql, comments.sql, verify.sql, load.sh, six CSVs, README
mariadb/     schema.sql, load.sql, verify.sql, run_all.sql, load.sh, six CSVs, README
mssql/       create_db.sql, schema.sql, load.sql, comments.sql, verify.sql, run_all.sql, load.ps1, six CSVs, README
oracle/      create_schema.sql, schema.sql, load.sql, comments.sql, verify.sql, run_all.sql, load.ps1, six CSVs, README
```

Each folder is self-contained and has its own README with the exact run steps. The CSVs are identical in all four.

## Data model

`departments` (self-referencing hierarchy), `locations`, `positions` (job level lives here), `employees`
(self-referencing manager link), `employee_history` (hire/termination, department, employment type, a
computed `employment_state`) and `compensation`. Four views (`vw_employee_detail`, `vw_departments`,
`vw_positions`, `vw_locations`) expose the original workbook column names for BI tools; headcounts and
counts are derived in the views, never stored.

## Differences between engines

| | PostgreSQL | MariaDB | SQL Server | Oracle |
|---|---|---|---|---|
| Bulk load | `\copy` | `LOAD DATA LOCAL INFILE` | `BULK INSERT` | external tables |
| Self-referencing FKs | deferrable | checks off during load, orphan checks after | disabled, re-enabled `WITH CHECK` | deferrable |
| `employment_state` | generated, stored | generated, stored | computed, persisted | virtual |
| Descriptions | `COMMENT ON` | inline `COMMENT` | extended properties | `COMMENT ON` |

## Notes

- Line endings matter: the CSV, SQL and shell files must stay LF (see `.gitattributes`).
- Scripts are re-runnable: they drop and recreate their own tables and views.
- The Oracle runner creates a `CORP_MOCK` schema with a throwaway default password for a local container;
  change it with `-SchemaPassword`. Do not reuse this setup for anything real.
- Known quirks kept on purpose: 116 employees were hired before their current manager; one department's
  budget dips year over year; Marketing sits under Sales; `employee_history` has one row per employee.

## Workbook changes, v1.2 to v1.3

Removed redundant text columns from Employees, renamed `LEVEL` to `JOB_LEVEL` (Oracle reserved word) and
`STATUS` to `EMPLOYMENT_TYPE`, replaced lookup formulas with stored values, typed salary and budgets as
integers, and moved the VP of Marketing under the Chief Revenue Officer. See the Data Dictionary sheet.
