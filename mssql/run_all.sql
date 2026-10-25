-- Runs everything in one sqlcmd session. Variable: DIR = folder of these files as SQL Server sees it.
:r $(DIR)/schema.sql
:r $(DIR)/load.sql
:r $(DIR)/comments.sql
:r $(DIR)/verify.sql
