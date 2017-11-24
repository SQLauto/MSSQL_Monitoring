--================================
-- 수동으로 로그 쉬핑 복원
-- ===============================
-- 리스트 확인
SELECT user_db_name, seq_no, log_file, copy_flag,copy_end_time,
		restore_flag, restore_start_time, restore_end_time,restore_duration
FROM logshipping_restore_list  WITH (NOLOCK)
WHERE reg_dt > CONVERT(NVARCHAR(10), GETDATE(), 120) AND user_db_name = 'TIGER'

EXEC master.dbo.sp_dba_process_user_kill 'TIGER'

sp_who


-- 복원 상태 시작 변경
UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_start_time =GETDATE() 
WHERE user_db_name = 'CUSTOMER' AND seq_no = 7982
GO

-- 복원
DECLARE @user_db_name			SYSNAME
DECLARE @dtGetDate				DATETIME
DECLARE @restore_full_name      NVARCHAR(256)
DECLARE @standy_file_name       NVARCHAR(256)
DECLARE @standy_dir				NVARCHAR(256)
DECLARE @file_dir				NVARCHAR(256)
DECLARE @log_file_name          NVARCHAR(200)
DECLARE @ret_code				INT


SET @dtGetDate = GETDATE()
SET @user_db_name = 'CUSTOMER'
SET @file_dir = 'N:\LogShipping' -- N: subdb3, I:superdb1
SET @standy_dir = 'N:\LogShipping\undo'
SET @log_file_name = 'LiteSpeed_CUSTOMER_tlog_200711160813.TRN'
SET @standy_file_name = 'STANDBY= N''' + @standy_dir + '\' + @user_db_name + '\' + @user_db_name + '_undo.ldf'''
SET @restore_full_name = @file_dir + '\' + @user_db_name + '\' + @log_file_name


EXEC @ret_code = master.dbo.xp_restore_log   
					@database = @user_db_name,
					@filename = @restore_full_name,
					@logging = 2, 
					@with =  @standy_file_name
				--	,@with = 'MOVE N''CUSTOMER_DATA_FG_P01_01'' TO N''K:\MSSQL\DATA\CUSTOMER_DATA_FG_P01_01.ndf'''
				--	,@with = 'MOVE N''CUSTOMER_DATA_FG_P02_01'' TO N''J:\MSSQL\DATA\CUSTOMER_DATA_FG_P02_01.ndf''' 
				--	,@with = 'MOVE N''CUSTOMER_DATA_FG_P03_01'' TO N''K:\MSSQL\DATA\CUSTOMER_DATA_FG_P03_01.ndf'''
SELECT @ret_code
GO


-- 복원완료 셋팅
UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_flag = 1, restore_end_time = GETDATE(), 
						restore_duration = DATEDIFF(ss, restore_start_time, GETDATE()), error_code = 0
WHERE user_db_name = 'CUSTOMER' AND seq_no = 7982
GO
