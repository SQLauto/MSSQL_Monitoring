-- =========================================
-- DB Bakup 정보
-- =========================================

-- 1.데이터베이스 복구 보델 변경
ALTER DATABASE pubs SET RECOVERY BULK_LOGGED
GO
/* BULK_LOGGED, FULL, SIMPLE */

SELECT DATABASEPROPERTYEX ( 'pubs' , 'Recovery')
GO

-- 2. 트랜젝션 로그 삭제하기
BACKUP LOG <dbName, sysname, userName> WITH NO_LOG
GO

BACKUP LOG <dbName, sysname, userName> WITH TRUNCATE_ONLY
GO

-- 3. 백업
BACKUP DATABASE <Database_Name, sysname, Database_Name> 
	TO  DISK =N'<dir,nvarhar,userDir>.BAK'
WITH 
	NOFORMAT, 
	NOINIT,  
	NAME = N'<Database_Name, sysname, Database_Name>-Full Database Backup', 
	SKIP, 
	STATS = 10; -- 모니터링 옵션
GO

-- 3-1. 파일 그룹 백업
USE master
GO

BACKUP DATABASE <Database_Name, sysname, Database_Name>
   FILE = N'<Logical_File_Name_1,sysname,Logical_File_Name_1>',
   FILEGROUP = N'PRIMARY',
   FILE = N'<Logical_File_Name_2, sysname, Logical_File_Name_2>', 
   FILEGROUP = N'<Filegroup_1, sysname, Filegroup_1>'
   TO  DISK =N'<dir,nvarhar,userDir>.BAK'
GO

-- 3-2. 차등 백업
BACKUP DATABASE <Database_Name, sysname, Database_Name> 
	TO  DISK =N'<dir,nvarhar,userDir>.BAK'
WITH 
	NOFORMAT, 
	NOINIT,  
	NAME = N'<Database_Name, sysname, Database_Name>-Full Database Backup', 
	SKIP, 
	STATS = 10, 
    DIFFERENTIAL; -- 차등 옵션
GO

-- 4. 데이터베이스에 백업 장치 추가
USE master
GO

EXEC master.dbo.sp_addumpdevice  
	@devtype = N'disk', 
	@logicalname = N'<Backup_Device_Name, SYSNAME, Backup_Device_Name>', 
	@physicalname = N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Backup\<Backup_Device_Name, SYSNAME, Backup_Device_Name>.bak'
GO


-- 전체 백업
BACKUP DATABASE pubs
    TO DISK = 'E:\SQLData\Backup\pubs_20070724.bak' WITH INIT
GO


-- 차등 백업
BACKUP DATABASE pubs 
    TO DISK = 'E:\SQLData\Backup\pubs_Diff_20070724.bak' WITH DIFFERENTIAL, NOINIT
GO


-- LiteSpeed Command
EXEC master.dbo.xp_backup_database @database='MyDB'
  , @filename = 'C:\MSSQL\Backup\MyDB_Backup.BAK'
  , @with = 'DIFFERENTIAL' 
GO
