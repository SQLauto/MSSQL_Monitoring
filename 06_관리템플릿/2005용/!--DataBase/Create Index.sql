-- ===========================
-- Create index
-- ===========================
USE <dbname, sysname, dbname>
GO

-- Create Basic Index
CREATE NONCLUSTERED INDEX <index_name, sysname, index_name> 
    ON dbo.<table_name, sysname, table_name> (
        <column_name, sysname, column_name>
    ) ON [PRIMARY]


-- Colustered Index
CREATE CLUSTERED INDEX <index_name, sysname, index_name> 
    ON dbo.<table_name, sysname, table_name> 
    (
        <column_name, sysname, column_name>
    ) ON [PRIMARY]


-- Unique Index
CREATE UNIQUE INDEX <index_name, sysname, index_name> 
   ON dbo.<table_name, sysname, table_name> 
    (
        <column_name, sysname, column_name> 
    ) ON [PRIMARY]


-- drop Index
DROP INDEX <table_name, sysname, table_name> .<index_name, sysname, index_name> 