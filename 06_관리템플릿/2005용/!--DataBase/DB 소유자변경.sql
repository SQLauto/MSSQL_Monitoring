-- ===========================================
-- DB ������ ����
-- ===========================================
USE <dbname,sysname,userDB>
GO

EXEC sp_changedbowner '<name,sysname,userName>'
GO

-- �̸� �����ϱ�
EXEC sp_renamedb <dbname,sysname,userDB>, <todbname,sysname,touserDB>
GO