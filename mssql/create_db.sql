-- Creates the database if it is missing. Variable: DBNAME (passed with sqlcmd -v).
SET NOCOUNT ON;
IF DB_ID(N'$(DBNAME)') IS NULL
    CREATE DATABASE [$(DBNAME)];
GO
