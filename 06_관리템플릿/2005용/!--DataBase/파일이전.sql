--=====================================
-- Detach database template
--=====================================
EXEC sp_detach_db @dbname = '<database_name, sysname, your_database_name>'
     ,@skipchecks = 'true'
     ,@KeepFulltextIndexFile = 'true'
GO
