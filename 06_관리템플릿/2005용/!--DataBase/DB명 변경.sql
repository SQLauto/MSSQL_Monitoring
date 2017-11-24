-- ======================================
-- db 변경
-- ======================================
EXEC sp_helpdb
GO

--1. 데이터베이스 명 변경
ALTER DATABASE <UserDBName, sysname, UserDBName> MODIFY NAME = <NewUserDBName, sysname, NewUserDBName>
GO
