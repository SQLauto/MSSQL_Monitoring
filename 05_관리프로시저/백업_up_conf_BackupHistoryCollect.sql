SET ANSI_NULLS ON							
GO							
SET QUOTED_IDENTIFIER ON							
GO							
-- =============================================							
-- Author:		<Author,,Daekyung Kim>					
-- Create date: <Create Date,,2010-09-15>							
-- Description:	<Description,, 해당서버의 DB 백업정보수집>						
-- =============================================							
CREATE PROCEDURE up_conf_BackupHistoryCollect
    @server_id          int,
    @instance_id        int,				
	@backupTime			varchar(5)
AS							
BEGIN							
	SET NOCOUNT ON;						
							
	DECLARE @stmt NVARCHAR(3000)						
	DECLARE @paramDef NVARCHAR(100)
	
	SET @paramDef = N'@server_id int, @instance_id int, @backupTime varchar(5)'
							
	IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='1' -- 2008 : add compressed_backup_size
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111)) + @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id				
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120), s.recovery_model_desc) AS recovery_model			
				,s.compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			
				,m.backupset_name
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method
			FROM sys.databases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						CASE 	
							WHEN bs.compatibility_level = 100 THEN bs.compressed_backup_size/1024/1024
							ELSE 0 END AS compressed_backup_size,
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
			WHERE s.name != ''tempdb''				
			'				
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='9' -- 2005 : add compressed_backup_size						
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime			
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111)) + @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id						
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120), s.recovery_model_desc) AS recovery_model			
				,s.compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			
				,m.backupset_name
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method	
			FROM sys.databases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						0 AS compressed_backup_size,	
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
			WHERE s.name != ''tempdb''				
			'
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)='8' -- 2000 : add compressed_backup_size						
		SET @stmt= N'					
			DECLARE @endDate DATETIME				
			DECLARE @time VARCHAR(8)				
			SET @time = '' ''+ @backupTime			
			SET @endDate = CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),111)) + @time				
			SELECT
				@server_id AS server_id
				,@instance_id AS instance_id						
				,@@servername AS server_name			
				,s.name AS database_name			
				,CONVERT(NVARCHAR(120),Databasepropertyex(s.name, ''Recovery'')) AS recovery_model			
				,s.cmptlevel AS compatibility_level			
				, CASE WHEN m.database_name is null THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS has_backupset			
				,m.backup_type			
				,m.backupset_name	
				,m.backup_size			
				,m.compressed_backup_size			
				,m.logical_device_name			
				,m.physical_device_name			
				,m.backup_start_date			
				,m.backup_finish_date
				,CASE
					WHEN m.database_name IS NOT NULL AND m.backupset_name = ''COMMVAULT GALAXY BACKUP'' THEN 2
					WHEN m.database_name IS NOT NULL THEN 1
					WHEN m.database_name IS NULL THEN 0
				END AS backup_method		
			FROM master.dbo.sysdatabases s with(nolock) 				
				LEFT OUTER JOIN(			
					SELECT		
						bs.database_name,	
						bs.type AS backup_type,	
						bs.compatibility_level,	
						bs.name AS backupset_name,	
						bs.backup_size/1024/1024 AS backup_size,	
						0 AS compressed_backup_size,	
						bf.logical_device_name, 	
						bf.physical_device_name,	
						bs.backup_start_date, 	
						bs.backup_finish_date	
					FROM msdb.dbo.backupset bs WITH(NOLOCK) INNER JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) ON bs.media_set_id = bf.media_set_id		
					WHERE bs.backup_finish_date BETWEEN DATEADD(DD,-1, @endDate) AND @endDate		
				) m ON s.name = m.database_name			
			WHERE s.name != ''tempdb''				
			'			
	EXEC sp_executesql @stmt, @paramDef, @server_id = @server_id, @instance_id = @instance_id, @backupTime = @backupTime	
END							
GO							
