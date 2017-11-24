-- ==================================
-- Create Default
-- =================================
USE <database_name, sysname, AdventureWorks>
GO

CREATE DEFAULT <schema_name, sysname, dbo>.<default_name, , today>
AS
   getdate()
GO

-- Bind the default to a column
EXEC sp_bindefault 
   N'<schema_name, sysname, dbo>.<default_name, , today>', 
   N'<table_schema,,HumanResources>.<table_name,,Employee>.<column_name,,HireDate>'
GO

-- ===================================
-- Defualt constraint
-- ===================================

ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, table_name>
   ADD CONSTRAINT df_<column_name, sysname, column_name>
   DEFAULT <default_expression, sysname, 0>
   FOR <column_name, sysname, column_name>
GO


-- ===================================
-- Drop Default Constraint template
-- ===================================

ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, table_name>
   DROP CONSTRAINT <default_constraint_name, sysname, default_constraint_name>
GO
