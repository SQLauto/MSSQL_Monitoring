--==================================
-- 환경 설정
--==================================
USE master
GO
EXEC sp_configure 'show advanced option', '1'
GO
RECONFIGURE WITH OVERRIDE
GO


EXEC sp_configure 'query governor cost limit', 0
GO
RECONFIGURE WITH OVERRIDE
GO

EXEC sp_configure
GO
