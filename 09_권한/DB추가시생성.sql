-- ==============================================
-- ������ ������ �־ DB�� �����Ǿ��� ���
-- ==============================================
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



EXEC sp_grantdbaccess 'dev_job', 'dev_job'
EXEC sp_grantdbaccess 'dev_ssis', 'dev_ssis'
go

EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_job'
EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_ssis'
go