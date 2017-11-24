-- ==============================================
-- 기존에 유저가 있어서 DB만 생성되었을 경우
-- ==============================================
-- 1. job, ssis를 생성하기 위한 role 생성
EXEC sp_addrole 'SSIS_GMARKET'
go


-- 2. 롤에 권한 부여
EXEC sp_addrolemember 'db_ddladmin', 'SSIS_GMARKET'
go
EXEC sp_addrolemember 'db_datareader', 'SSIS_GMARKET'
go
EXEC sp_addrolemember 'db_datawriter', 'SSIS_GMARKET'
go
GRANT EXECUTE  TO SSIS_GMARKET -- 모두 실행권한
go 



EXEC sp_grantdbaccess 'dev_job', 'dev_job'
EXEC sp_grantdbaccess 'dev_ssis', 'dev_ssis'
go

EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_job'
EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_ssis'
go