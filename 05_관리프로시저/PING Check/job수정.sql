

USE [msdb]
GO
/****** Object:  Step [2. Cluster  Status 수집]    Script Date: 2016-09-05 오후 5:33:07 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'c1357b01-0078-475b-9f44-2adf66fb5891', @step_id=2
GO
USE [msdb]
GO
/****** Object:  Step [1. SMS발송]    Script Date: 2016-09-05 오후 5:33:07 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'c1357b01-0078-475b-9f44-2adf66fb5891', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'c1357b01-0078-475b-9f44-2adf66fb5891', @step_name=N'1. SMS발송', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=3, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @msg VARCHAR(1000), @sms VARCHAR(1000)
set @msg = ''['' + @@servername  + '']'' --Agent Service가 시작되었습니다.
set @msg = @msg + convert(varchar(20) , getdate(), 108)
set @msg = 	@msg + 	'' SQLAgent 재시작''

set @sms = ''sqlcmd -S EPDBAM -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''''DBA'''','''''' + @msg + ''''''"''  
exec xp_cmdshell  @sms
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'c1357b01-0078-475b-9f44-2adf66fb5891', @step_name=N'2. Cluster  Status 수집', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
--USE DBMON
--GO


--CREATE TABLE DB_MON_CLUSTERINFO (
--	  SEQ INT IDENTITY
--	, INFO VARCHAR(255)
--	, UP_TIME DATETIME
--	, REG_DATE DATETIME
--	)
--WITH (DATA_COMPRESSION = PAGE)



SET NOCOUNT ON
DECLARE @TEMP TABLE(INFO NVARCHAR(255))
DECLARE @UPTIME DATETIME

INSERT INTO @TEMP EXEC(''XP_CMDSHELL "CLUSTER GROUP | FINDSTR MSSQLSERVER" '')
 
SELECT @UPTIME= CREATE_DATE FROM SYS.DATABASES WITH(NOLOCK) WHERE NAME = ''TEMPDB''

INSERT INTO DBMON.dbo.DB_MON_CLUSTERINFO(INFO, UP_TIME, REG_DATE)
SELECT INFO, @UPTIME as UP_TIME, getdate() AS REG_DATE
FROM @TEMP WHERE INFO IS NOT NULL
', 
		@database_name=N'DBMON', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'c1357b01-0078-475b-9f44-2adf66fb5891', @step_name=N'3.Ping Check', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=1, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'exec xp_cmdshell ''schtasks.exe /Run /TN "[DB]PingCheckLocal"''
exec xp_cmdshell ''schtasks.exe /Run /TN "[DB]PingCheckStorage"''', 
		@database_name=N'master', 
		@flags=32
GO
