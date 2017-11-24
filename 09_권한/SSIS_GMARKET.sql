use master
go

--===============================================
-- 로그인 생성
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

-- 3. 모든 DB에 해당 롤을 만들어야함.
USE DBA
go
-- 각각 실행하고 해당 결과를 남겨주세요. 
-- DB가 없거나 부여되지 않으면 에러 표시 납니다.
-- 어느 DB인지도 확인해 주면 더 좋습니다.

EXEC up_dba_grant_database 'dev_job', 'SSIS_GMARKET', 'F'
go
EXEC up_dba_grant_database 'dev_ssis', 'SSIS_GMARKET', 'F'
go

--- 프로시저 실행이 이상하면  master,model msdb , 라이트스피드 db, tempdb 빼고 
--모두 실행해 주세요.
/*
    EXEC sp_grantdbaccess 'dev_job', 'dev_job'
    EXEC sp_grantdbaccess 'dev_ssis', 'dev_ssis'
    go

    EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_job'
    EXEC sp_addrolemember 'SSIS_GMARKET', 'dev_ssis'
    go

*/


-- master, msdb에는 특별한 권한이 필요하다. 수집을 위해서 

EXEC sp_addsrvrolemember 'dba_ssis ', 'sysadmin'
go
