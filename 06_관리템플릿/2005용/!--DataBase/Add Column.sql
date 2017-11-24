--==========================================================================
-- Add column template
--
-- This template creates a table, then it adds a new column to the table.
--==========================================================================
USE <dbname,sysname,dbname>
GO

-- 1.컬럼 추가
ALTER TABLE dbo.<table_name, sysname, table_name>
    ADD COLUMN <new_column, sysname, column1>   <new_datatype, , NVARCHAR>
GO

-- 2. 컬럼 삭제
ALTER TABLE dbo.<table_name, sysname, table_name>
    DROP COLUMN <new_column, sysname, column1>
GO

-- ===================================
-- 컬럼 변경
-- ===================================
ALTER TABLE dbo.<table_name, sysname, table_name>
    ALTER COLUMN <column_name, sysname, column_name>  <new_datatype, , NVARCHAR>
GO