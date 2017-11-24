-- ===========================
-- Create Login
-- ===========================

-- 1. ���� ���� ����
CREATE LOGIN <userName, sysname, userName> WITH PASSWORD ='<password, nvarchar,password>',
		DEFAULT_DATABASE = <dbname, sysname, dbname>,
		CHECK_POLICY = ON | OFF,
		CHECK_EXPIRATION = ON | OFF,		-- ��ȣ ���� ��å ����
		SID = [SID ��];
GO

-- 1-1 ������ ������ �������� �α��� �����
CREATE LOGIN [ADVWORKS\fogisu] FROM WINDOWS;
GO


--2. �α��� ����
ALTER LOGIN <userName, sysname, userName> 
		WITH PASSWORD ='<password, nvarchar,password>',
		DEFAULT_DATABASE = <dbname, sysname, dbname>,
GO

-- 2-1 Ȱ��ȭ /��Ȱ��ȭ
ALTER LOGIN <userName, sysname, userName>  ENABLE;
GO

--3. �α��� ����
DROP LOGIN <userName, sysname, userName>;
GO


-- 4. �α��� ������ �� �Ǿ����� Ȯ��
USER <dbname, sysname, dbname>
GO

EXEC sp_change_user_login 'REPORT'
GO

EXEC sp_change_user_login 'Update_One',  'Mary', NULL
GO