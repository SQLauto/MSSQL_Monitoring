/*----------------------------------------------------
    Date    : 2007-12-06
    Note    : ��Ƽ�� �׷캰 row �� ���� ���̺�
              ��Ƽ���� �Ǿ��ִ� �� DB���� ������ ��
    No.     :
*----------------------------------------------------*/
CREATE TABLE dbo.PARTITION_TABLE_INFO
(
    db_name             sysname         not null,
    name                sysname         not null,
    boundary            varchar(5)      not null,
    range               varchar(100)    null,
    partition_number    int             not null,
    file_group          sysname         not null,
    rows                bigint          not null CONSTRAINT DF__PARTITION_TABLE_INFO__ROWS DEFAULT(0),
    reg_dt              datetime        not null CONSTRAINT DF__PARTITION_TABLE_INFO_REG_DT DEFAULT(GETDATE())
) ON [PRIMARY]


ALTER TABLE dbo.PARTITION_TABLE_INFO ADD CONSTRAINT PK__PARTITION_TABLE_INFO__NAME__PARTITION_NUMBER PRIMARY KEY NONCLUSTERED
    (name, partition_number) WITH FILLFACTOR = 90 ON [PRIMARY]
GO

CREATE CLUSTERED INDEX CIDX__PARTITION_TABLE_INFO__REG_DT ON dbo.PARTITION_TABLE_INFO (reg_dt) WITH FILLFACTOR = 90 ON [PRIMARY]
GO


--===========================================
--ACCOUNTDB ��� �۾�
--===========================================
USE [msdb]
GO
/****** ��ü:  Job [[DBA]] ��Ƽ�����̺� ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:43 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** ��ü:  JobCategory [[Uncategorized (Local)]]]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:44 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[DBA] ��Ƽ�����̺� ����', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'������ �����ϴ�.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'dba', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [���̺� ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:47 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'���̺� ����', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'TRUNCATE TABLE dbo.PARTITION_TABLE_INFO', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [TIGER ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:47 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'TIGER ����', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''TIGER''', 
		@database_name=N'TIGER', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [CUSTOMER ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CUSTOMER ����', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''CUSTOMER''', 
		@database_name=N'CUSTOMER', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [EVENT����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EVENT����', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''EVENT''', 
		@database_name=N'EVENT', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [ACCOUNTS����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ACCOUNTS����', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''ACCOUNTS''', 
		@database_name=N'ACCOUNTS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [ACCTCLOSE]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ACCTCLOSE', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''ACCTCLOSE''', 
		@database_name=N'ACCTCLOSE', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [PASTACCT ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:33:50 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PASTACCT ����', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''PASTACCT''', 
		@database_name=N'PASTACCT', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'��Ƽ����������', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20071207, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


--================================================== 
--PASTDB�� �۾�
--==================================================
USE [msdb]
GO
/****** ��ü:  Job [[DBA]] ��Ƽ�����̺� ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:30:54 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** ��ü:  JobCategory [[Uncategorized (Local)]]]    ��ũ��Ʈ ��¥: 12/07/2007 16:30:54 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[DBA] ��Ƽ�����̺� ����', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'dba', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [���̺����]    ��ũ��Ʈ ��¥: 12/07/2007 16:30:54 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'���̺����', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'TRUNCATE TABLE dbo.PARTITION_TABLE_INFO', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** ��ü:  Step [PAST ����]    ��ũ��Ʈ ��¥: 12/07/2007 16:30:54 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PAST ����', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.up_DBA_insert_partition_table_info ''PAST''', 
		@database_name=N'PAST', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
