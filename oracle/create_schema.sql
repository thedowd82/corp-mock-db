-- Run once as SYSDBA from inside the container (the runner does this).
-- Arguments: &1 = password for the CORP_MOCK schema, &2 = folder with the CSVs (as the container sees it), &3 = PDB name.
-- Creates the CORP_MOCK schema (Oracle's equivalent of a database) and a read-only directory object for the CSVs.
WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON
ALTER SESSION SET CONTAINER = &3;

DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_users WHERE username = 'CORP_MOCK';
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER corp_mock IDENTIFIED BY "&1" DEFAULT TABLESPACE users QUOTA UNLIMITED ON users';
    DBMS_OUTPUT.PUT_LINE('Created schema CORP_MOCK.');
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER corp_mock IDENTIFIED BY "&1" QUOTA UNLIMITED ON users';
    DBMS_OUTPUT.PUT_LINE('Schema CORP_MOCK already exists; password reset to the one supplied.');
  END IF;
END;
/
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO corp_mock;
CREATE OR REPLACE DIRECTORY corp_mock_dir AS '&2';
GRANT READ ON DIRECTORY corp_mock_dir TO corp_mock;
EXIT
