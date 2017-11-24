-- ===========================================
-- DB 소유자 변경
-- ===========================================
USE <dbname,sysname,userDB>
GO

EXEC sp_changedbowner '<name,sysname,userName>'
GO

-- 이름 변경하기
EXEC sp_renamedb <dbname,sysname,userDB>, <todbname,sysname,touserDB>
GO