-- ======================================
-- db ����
-- ======================================
EXEC sp_helpdb
GO

--1. �����ͺ��̽� �� ����
ALTER DATABASE <UserDBName, sysname, UserDBName> MODIFY NAME = <NewUserDBName, sysname, NewUserDBName>
GO
