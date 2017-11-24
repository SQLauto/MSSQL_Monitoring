SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_dba_backup_selectbackupset' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_dba_backup_selectbackupset
*/

/*************************************************************************  
* 프로시저명  : dbo.up_dba_backup_selectbackupset 
* 작성정보    : 2007-12-18 by choi bo ra
* 관련페이지  :  
* 내용        : 각 장비마다 백업 결과 셋 정보, 백업 성공/실패 보고에 사용
                모든 장비에 설치함
* 수정정보    : 2007-12-29 by choi bo ra, 모든 DB에 실패성공을 표시해야함.
                2008-01-28 by choi bo ra, 장비의 서버명 조건 필요 (로그쉬핑의 경우 다르게 나옴)
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_backup_selectbackupset
     @reg_dt        DATETIME = NULL
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE  @from_date DATETIME
DECLARE  @to_date   DATETIME
DECLARE  @server_name   SYSNAME
DECLARE  @ret_dt     DATETIME
SET @server_name = CONVERT(sysname, SERVERPROPERTY('ServerName'))
SET @reg_dt = GETDATE()

/* BODY */
IF @reg_dt IS NULL 
BEGIN
    -- 전일 09:00  ~ 오늘 09시 부터 가져옴
    SET @from_date = CONVERT(DATETIME, (CONVERT(NVARCHAR(10), DATEADD(dd, -1, GETDATE()), 120) + ' 09:00:00'), 120)
    SET @to_date = CONVERT(DATETIME, (CONVERT(NVARCHAR(10), GETDATE(), 120) + ' 09:00:01'), 120)
END
ELSE
BEGIN
    SET @from_date = CONVERT(DATETIME, (CONVERT(NVARCHAR(10), DATEADD(dd, -1, @reg_dt), 120) + ' 09:00:00'), 120)
    SET @to_date = CONVERT(DATETIME, (CONVERT(NVARCHAR(10), @reg_dt, 120) + ' 09:00:01'), 120)
END

SELECT
    ISNULL(bs.server_name, @server_name) AS server_name
,   sysdb.name AS database_name
,   ISNULL(bs.backup_set_id, 0) AS backup_set_id
,   ISNULL(bmf.family_sequence_number,0) AS family_sequence_number
,   CONVERT(NVARCHAR(20), 'FULL BACKUP') AS type
,   CONVERT(NVARCHAR(60),(databasepropertyex(sysdb.name,'Recovery'))) AS recovery_model
,	bs.name
,   (CASE WHEN DATEDIFF (dd,bs.backup_finish_date,@ret_dt) <= 1  THEN 1 ELSE 2 END) AS successFlag
,   cast(datediff(dd, bs.backup_finish_date, GETDATE()) AS varchar(10)) AS backup_diffday
,   bs.backup_start_date
,   bs.backup_finish_date
,   CONVERT(NVARCHAR(20), (str(cast(backup_size AS decimal(20,2)) / 1048576 ,10,2) + ' MB')) AS backup_size
,   bmf.physical_device_name
,   bs.software_build_version
,   bs.first_lsn
,   bs.last_lsn
,   bs.checkpoint_lsn
,   bs.database_backup_lsn
,   CONVERT(NVARCHAR(10),(CASE bs.compatibility_level WHEN 80 THEN 'MS-SQL2000'
                                WHEN 90 THEN 'MS-SQL2005' END)) as compatibility_level
,   @reg_dt AS reg_date
FROM msdb.dbo.backupmediafamily as bmf with (nolock)
		INNER JOIN msdb.dbo.backupset as bs with (nolock) on bmf.media_set_id = bs.media_set_id
		INNER JOIN (SELECT max(backup_set_id) as backup_set_id FROM msdb.dbo.backupset WITH (NOLOCK)
					WHERE type  = 'D' AND backup_start_date >= @from_date AND backup_start_date < @to_date
					GROUP BY database_name) AS to1 ON bs.backup_set_id = to1.backup_set_id
	    RIGHT JOIN (SELECT name FROM sys.sysdatabases 
					WHERE STATUS & 1024 <> 1024 
						AND  (name <> 'tempdb' AND name <> 'LiteSpeedLocal' AND  name <> 'pubs'  AND name <> 'Northwind'
						AND name <> 'AdventureWorks' AND name <> 'AdventureWorksDW') ) AS sysdb ON sysdb.name  = bs.database_name
--WHERE server_name = @server_name

UNION ALL
SELECT 
    ISNULL(bs.server_name, @server_name) AS server_name
,   sysdb.name AS database_name
,   ISNULL(bs.backup_set_id, 0) AS backup_set_id
,   ISNULL(bmf.family_sequence_number,0) AS family_sequence_number
,   CONVERT(NVARCHAR(20), 'LOG BACKUP') AS type
,   CONVERT(NVARCHAR(60),(databasepropertyex(sysdb.name,'Recovery'))) AS recovery_model
,	bs.name
,   (CASE WHEN DATEDIFF (hh,bs.backup_finish_date,@ret_dt) <= 7  THEN 1 ELSE 2 END) AS successFlag
,   cast(datediff(hh, bs.backup_finish_date, GETDATE()) AS varchar(10)) AS backup_diffday
,   bs.backup_start_date
,   bs.backup_finish_date
,   CONVERT(NVARCHAR(20), (str(cast(backup_size AS decimal(20,2)) / 1048576 ,10,2) + ' MB'))AS backup_size
,   bmf.physical_device_name
,   bs.software_build_version
,   bs.first_lsn
,   bs.last_lsn
,   bs.checkpoint_lsn
,   bs.database_backup_lsn
,   CONVERT(NVARCHAR(10),(CASE bs.compatibility_level WHEN 80 THEN 'MS-SQL2000'
                                WHEN 90 THEN 'MS-SQL2005' END)) as compatibility_level
,   @reg_dt AS reg_date
FROM msdb.dbo.backupmediafamily as bmf with (nolock)
		INNER JOIN msdb.dbo.backupset as bs with (nolock) on bmf.media_set_id = bs.media_set_id
		INNER JOIN (
					SELECT MAX(backup_set_id) AS  backup_set_id FROM msdb.dbo.backupset 
					WHERE backup_start_date >= @from_date AND backup_start_date < @to_date
							AND type = 'L'
					GROUP BY database_name ) AS to1 ON to1.backup_set_id = bs.backup_set_id
		RIGHT JOIN (SELECT name FROM sys.sysdatabases  
					WHERE STATUS & 1024 <> 1024 
						AND  (name <> 'tempdb' AND name <> 'LiteSpeedLocal' AND  name <> 'pubs'  AND name <> 'Northwind'
						AND name <> 'AdventureWorks' AND name <> 'AdventureWorksDW')
						AND databasepropertyex(name,'Recovery') <> 'SIMPLE') AS sysdb ON sysdb.name  = bs.database_name
--WHERE server_name = @server_name
ORDER BY sysdb.name ,backup_set_id

IF @@ERROR <> 0 RETURN

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
