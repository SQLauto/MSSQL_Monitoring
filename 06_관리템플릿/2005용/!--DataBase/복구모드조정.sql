--======================
--DB 복구모드 조정
--=====================
-- GMARKET PM 작업시 사용. 
--작업 전
--1. 복구모드 변경
ALTER DATABASE TIGER SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE CUSTOMER SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE EVENT SET RECOVERY BULK_LOGGED
go 
ALTER DATABASE SETTLE SET RECOVERY BULK_LOGGED
go 

--확인
SELECT DATABASEPROPERTYEX('TIGER','RECOVERY')
SELECT DATABASEPROPERTYEX('CUSTOMER','RECOVERY')
SELECT DATABASEPROPERTYEX('EVENT','RECOVERY')
SELECT DATABASEPROPERTYEX('SETTLE','RECOVERY')

--3. maxdop 변경
exec sp_configure 'show advanced option', 1
go 
reconfigure with override
go 

exec sp_configure 'max degree of parallelism', 8
go 
reconfigure with override
go 

-- 작업 시작


---------------------------------------------------
--작업 후
---------------------------------------------------
ALTER DATABASE TIGER SET RECOVERY FULL
go 
ALTER DATABASE CUSTOMER SET RECOVERY FULL
go 
ALTER DATABASE EVENT SET RECOVERY FULL
go 
ALTER DATABASE SETTLE SET RECOVERY FULL
go 

--확인
SELECT DATABASEPROPERTYEX('TIGER','RECOVERY')
SELECT DATABASEPROPERTYEX('CUSTOMER','RECOVERY')
SELECT DATABASEPROPERTYEX('EVENT','RECOVERY')
SELECT DATABASEPROPERTYEX('SETTLE','RECOVERY')


exec sp_configure 'show advanced option', 1
go 
reconfigure with override
go 

exec sp_configure 'max degree of parallelism', 2
go 
reconfigure with override
go 




------------------------------------------------------------------------------------------------------------------------------------

