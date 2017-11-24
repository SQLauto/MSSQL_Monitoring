use master
go

--===============================================
-- �α��� ����
CREATE LOGIN dev_ssis WITH PASSWORD ='ssis3950',
		DEFAULT_DATABASE = CUB,
		CHECK_POLICY = OFF,
		CHECK_EXPIRATION = OFF
GO

CREATE LOGIN dev_job WITH PASSWORD ='job3950',
		DEFAULT_DATABASE = CUB,
		CHECK_POLICY = OFF,
		CHECK_EXPIRATION = OFF
GO


CREATE LOGIN dba_ssis WITH PASSWORD ='dba3950',
		DEFAULT_DATABASE = CUB,
		CHECK_POLICY = OFF,
		CHECK_EXPIRATION = OFF
GO

--=================================================




-- 1. job, ssis�� �����ϱ� ���� role ����
EXEC sp_addrole 'SSIS_GMARKET'
go

-- 2. �ѿ� ���� �ο�
EXEC sp_addrolemember 'db_ddladmin', 'SSIS_GMARKET'
go
EXEC sp_addrolemember 'db_datareader', 'SSIS_GMARKET'
go
EXEC sp_addrolemember 'db_datawriter', 'SSIS_GMARKET'
go
GRANT EXECUTE  TO SSIS_GMARKET -- ��� �������
go 

-- 3. ��� DB�� �ش� ���� ��������.
USE DBA
go
-- ���� �����ϰ� �ش� ����� �����ּ���. 
-- DB�� ���ų� �ο����� ������ ���� ǥ�� ���ϴ�.
-- ��� DB������ Ȯ���� �ָ� �� �����ϴ�.

EXEC up_dba_grant_database 'dev_job', 'SSIS_GMARKET', 'F'
go
EXEC up_dba_grant_database 'dev_ssis', 'SSIS_GMARKET', 'F'
go

--- ���ν��� ������ �̻��ϸ�  master,model msdb , ����Ʈ���ǵ� db, tempdb ���� 
--��� ������ �ּ���.
/*
    EXEC sp_grantdbaccess 'dev_job', 'dev_job'
    EXEC sp_grantdbaccess 'dev_ssis', 'dev_ssis'
    go

    EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_job'
    EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_ssis'
    go

*/


-- master, msdb���� Ư���� ������ �ʿ��ϴ�. ������ ���ؼ� 

EXEC sp_addsrvrolemember 'dba_ssis ', 'sysadmin'
go
