-- ======================================
-- db ���� �׷� �߰�
-- ======================================
-- 1. ���� �׷��� �߰�
ALTER DATABASE <DBName,sysname,userDB>
    ADD FILEGROUP <FilegorupName, nvarchar, userFilegroup>
GO

--2.������ ������ �߰�
ALTER DATABASE <DBName,sysname,userDB> 
	ADD FILE (
		Name = <fileName, nvarchar, userFile>,
		FILENAME '<dir, nvarchar, userdir>',
		SIZE = , 
		MAXSIZE = , 
		FILEGROWTH = ) TO FILEGROUP '<FilegorupName, nvarchar, userFilegroup>'
GO

-- ==================================
-- db ���� �׷� ����
-- ==================================
-- 1. ���� �׷�� ����
ALTER DATABASE <DBName, sysname, userDB> MODIFY FILEGROUP <FileGroupName, nvarchar, userFileGroup> 
	NAME = <NewFileGroup, nvarchar, NewFileGroup>
GO
-- �ش� ���� �׷쿡 ��ü���� �������� �ʾƾ� ��



-- ==================================
-- db ���� ����
-- ==================================
-- 1. ���� ������ ����
ALTER DATABASE <DBName,sysname,userDB>
	MODIFY FILE (
		Name = <fileName, nvarchar, userFile>,
		FILENAME '<dir, nvarchar, userdir>',
		SIZE = , 
		MAXSIZE = , 
		FILEGROWTH = ) TO FILEGROUP '<FilegorupName, nvarchar, userFilegroup>'
GO




-- =================================
-- ���� �׷�/���� ����
-- ==================================
-- 1.�׷� ����
ALTER DATABASE <DBName, sysname, userDB>
	REMOVE FILEGROUP <FileGroupName, nvarchar, userFileGroup> 
GO

-- 2.���� ����
ALTER DATABASE <DBName, sysname, userDB>
	REMOVE FILE <fileName, nvarchar, userFile>
GO



-- ===============================
-- �⺻ ���� �׷� ����
-- ===============================
ALTER DATABASE <DBName, sysname, userDB>
MODIFY FILEGROUP <FileGroupName, nvarchar, userFileGroup> DEFAULT;
GO

