-- ================================
-- 백업파일 복구, 검증
-- ================================
-- 1.특정 백업 장치의 모든 백업 세트에 대한 백업 헤더 정보를 모두 포함하는 결과 집합을 반환합니다. 

RESTORE HEADERNLY FROM DISK = '<dir, nvarchar, dir>.bak'
GO

-- 2. 백업 셋트에 포함된 데이터베이스와 로그 파일 확인
RESTORE FILELISTONLY FROM DISK = '<dir, nvarchar, dir>.bak'
    WITH FILE = 3   -- { backup_set_file_number }
GO


-- 3. 백업 파일 검증
RESTORE VERIFYONLY FROM DISK ='<dir,nvarhcar, dir>.bak'
    WITH FILE = 3
GO
   
-- 4.데이터베이스 복원
USE master
GO

RESTORE DATABASE <Database_Name, sysname, Database_Name>
	FROM  DISK = N'<dir, nvarchar, dir>.bak' 
WITH  
	FILE = 3,  
	NOUNLOAD,  
	REPLACE,
	STATS = 10
GO


-- 4-1. Standy로 복원
RESTORE DATABASE [TESTDB] 
    FROM DISK = N'D:\TraceData\TestDB.bak' 
    WITH FILE = 1
		,MOVE 'TestDb' To 'E:\MSSQL\DATA\TestDB.mdf'
		,MOVE 'TestDB_Log' TO 'E:\MSSQL\Log\TestDB_log.ldf'
		,STANDBY = N'D:\TraceData\TestDB\testdb_Undo.ldf'
		,REPLACE
		,STATS = 1
	
GO    

/* LiteSpeed
exec master.dbo.xp_restore_database 
@database = 'TESTDB', 
@filename = N'D:\TraceData\TestDB.bak' ,
@filenumber = 1, 
@with = 'STANDBY = ''D:\TraceData\TestDB\testdb_Undo.ldf''', 
@with = 'STATS = 1', 
@with = 'REPLACE',
@with = 'MOVE N''TestDb'' TO N''E:\MSSQL\DATA\TestDB.mdf''', 
@with = 'MOVE N''TestDB_Log'' TO N''E:\MSSQL\Log\TestDB_log.ldf''' 
*/


--5. 파일그룹 복원  Restore filegroups - one at a time
RESTORE DATABASE [<database_name, sysname, TestDB>] 
	FILE = N'<database_name, sysname, TestDB>_data' 
	FROM DISK = N'<dir,nvarhcar,dir>/<database_name, sysname, TestDB>.bak' 
	WITH  
		FILE = 1,  
		NORECOVERY,  
		NOUNLOAD,  
		STATS = 10
GO

RESTORE DATABASE [<database_name, sysname, TestDB>] 
	FILE = N' <database_name, sysname, TestDB>_<filegroup_name1, sysname, FG_1>' 
	FROM DISK = N'<dir,nvarhcar,dir>/<database_name, sysname, TestDB>.bak' 
	WITH  
		FILE = 1,  
		NORECOVERY,  
		NOUNLOAD,  
		STATS = 10
GO

RESTORE DATABASE [<database_name, sysname, TestDB>] 
	FILE = N' <database_name, sysname, TestDB>_<filegroup_name2, sysname, FG_2>' 
	FROM DISK = N'<dir,nvarhcar,dir>/<database_name, sysname, TestDB>.bak' 
	WITH  
		FILE = 1,  
		NORECOVERY,    /* 차등 복원할 때 마지막일때 RECOVERY 사용 */
		NOUNLOAD,  
		STATS = 10

GO


-- 6. Restore log
RESTORE LOG [<database_name, sysname, TestDB>] 
	FROM DISK = N'<dir,nvarhcar,dir>/<database_name, sysname, TestDB>.bak' 
	WITH  
		FILE = 2,  
		NOUNLOAD,  
		STATS = 10
GO
