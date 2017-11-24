-- ================================
-- ������� ����, ����
-- ================================
-- 1.Ư�� ��� ��ġ�� ��� ��� ��Ʈ�� ���� ��� ��� ������ ��� �����ϴ� ��� ������ ��ȯ�մϴ�. 

RESTORE HEADERNLY FROM DISK = '<dir, nvarchar, dir>.bak'
GO

-- 2. ��� ��Ʈ�� ���Ե� �����ͺ��̽��� �α� ���� Ȯ��
RESTORE FILELISTONLY FROM DISK = '<dir, nvarchar, dir>.bak'
    WITH FILE = 3   -- { backup_set_file_number }
GO


-- 3. ��� ���� ����
RESTORE VERIFYONLY FROM DISK ='<dir,nvarhcar, dir>.bak'
    WITH FILE = 3
GO
   
-- 4.�����ͺ��̽� ����
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


-- 4-1. Standy�� ����
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


--5. ���ϱ׷� ����  Restore filegroups - one at a time
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
		NORECOVERY,    /* ���� ������ �� �������϶� RECOVERY ��� */
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
