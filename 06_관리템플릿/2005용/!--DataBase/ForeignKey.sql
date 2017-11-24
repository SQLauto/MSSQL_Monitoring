-- ======================
-- Foreign Key
-- ======================
USE <dbname, sysname, dbname>
GO

ALTER TABLE dbo.<tableName, sysname, tableName>
    ADD CONSTRAINT FK_  FOREIGN KEY  ( column [ ,...n ] )
        REFERENCES ref_table ( column [,...n])
GO

-- ����
ALTER TABLE dbo.<tableName, sysname, tableName>
    DROP CONSTRAINT FK_
GO
