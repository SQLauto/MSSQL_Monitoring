--==========================================================================
-- Add column template
--
-- This template creates a table, then it adds a new column to the table.
--==========================================================================
USE <dbname,sysname,dbname>
GO

-- 1.�÷� �߰�
ALTER TABLE dbo.<table_name, sysname, table_name>
    ADD COLUMN <new_column, sysname, column1>   <new_datatype, , NVARCHAR>
GO

-- 2. �÷� ����
ALTER TABLE dbo.<table_name, sysname, table_name>
    DROP COLUMN <new_column, sysname, column1>
GO

-- ===================================
-- �÷� ����
-- ===================================
ALTER TABLE dbo.<table_name, sysname, table_name>
    ALTER COLUMN <column_name, sysname, column_name>  <new_datatype, , NVARCHAR>
GO