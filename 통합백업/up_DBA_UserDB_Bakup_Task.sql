SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_UserDB_Bakup_Task' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_UserDB_Bakup_Task
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_UserDB_Bakup_Task 
* 작성정보    : 2007-08-19 김태환
* 관련페이지  : 
* 내용        : 데이터베이스의 전체 백업 관리
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_UserDB_Bakup_Task (
    @user_db_name        SYSNAME, 
    @backup_type         TINYINT = 2,  --1:Native, 2:LiteSpeed,
    @file_dir            NVARCHAR(256) = NULL,
    @verify              bit = 1,                   -- verify backup
    @define_threads      SMALLINT = 16,
    @define_transfersize INT = 2097152,
    @ret_code            INT OUTPUT
)
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET @ret_code = -1

/* USER DECLARE */
DECLARE @backup_file_name      NVARCHAR(100)
DECLARE @backup_type_name      NVARCHAR(25)
DECLARE @backup_full_name      NVARCHAR(256)
DECLARE @backup_name           NVARCHAR(50)
DECLARE @dtGetDate             DATETIME
DECLARE @backup_no             INT

SET @dtGetDate = GETDATE()

/* BODY */
SET @user_db_name = UPPER(@user_db_name)


-- check database exists and is online
IF (DB_ID(@database) IS NULL) OR (DATABASEPROPERTYEX(@database,'Status')<>'ONLINE')
BEGIN                   				
RAISERROR('Database %s is invalid or database status is not ONLINE',16,1,@database)
  SET @ret_code = 11
  RETURN	
END

-- check @backuptype is valid
IF UPPER(@backuptype) NOT IN ('LOG','DB','DIFF')
BEGIN                   				
RAISERROR('%s is not a valid option for @backuptype',16,1,@backuptype)
  SET @ret_code = 1
  RETURN	
END

-- check recovery mode is correct if trying log backup
IF (DATABASEPROPERTYEX(@database,'Recovery')='SIMPLE' and @backuptype = 'LOG')
BEGIN                   				
RAISERROR('%s is not a valid option for database %s because it is in SIMPLE recovery mode',16,1,@backuptype,@database)
  SET @ret = 1
GOTO CLEANUP	
END

-- Fil
IF @file_dir = '' OR @file_dir = NULL
BEGIN
    SET @ret_code = 12    -- 디렉토리 경로 입력
    RETURN
END



IF @backup_type = 1 
BEGIN
    SET @backup_type_name = @user_db_name + '_db'
END
ELSE IF @backup_type = 2 
BEGIN
    SET @backup_type_name = 'LiteSpeed_' + @user_db_name + '_db'
END
ELSE
BEGIN
    SET @ret_code = 13    -- 트랜젝션로그 유형이 잘 못 되었습니다.
    RETURN
END

-- 파일 이름
SET @backup_file_name = @backup_type_name + '_'
                    + replace(replace(convert(char(10), @dtGetDate, 121), '-', ''), ' ', '')   
                    + right(replace('00' + convert(char(2), datepart(hh, @dtGetDate)), ' ', ''), 2)  
                    + right(replace('00' + convert(char(2), datepart(mi, @dtGetDate)), ' ', ''), 2)  
                    + '.BAK'  
-- 전체경로
SET @backup_full_name = @file_dir + '\' + @user_db_name + '\' + @backup_file_name
-- 백업명
SET @backup_name = @user_db_name + ' Backup'

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN

-- Step 2. 백업
IF @backup_type = 1
BEGIN
--    BACKUP LOG @user_db_name
--        TO DISK = @backup_full_name
--    
    SET @ret_code = @@ERROR
    
END
ELSE IF @backup_type = 2  -- LiteSpeed
BEGIN
     EXEC master.dbo.xp_backup_database   
         @database = @user_db_name  
        ,@filename = @backup_full_name  
        ,@backupname = @backup_name  
        ,@init = 1  
        ,@logging = 2  
        ,@maxtransfersize = @define_transfersize  
        ,@threads = @define_threads  
        ,@buffercount = 20  
   
    SET @ret_code = @@ERROR
END

-- Step 3. error check
IF @ret_code <> 0
BEGIN
--    UPDATE dbo.LOGSHIPPING_BACKUP_LIST 
--    SET backup_flag = 2, -- 백업실패
--        error_code = @ret_code
--    WHERE user_db_name = @user_db_name AND seq_no = @seq_no
--    
    SET @ret_code = @@ERROR
    IF @ret_code <> 0 RETURN
END
ELSE
BEGIN
--    UPDATE dbo.LOGSHIPPING_BACKUP_LIST 
--    SET backup_flag = 1, -- 백업성공
--        backup_start_time = @dtGetDate,
--        backup_end_time = GETDATE(),
--        backup_duration = DATEDIFF(s, @dtGetDate, GETDATE()),
--        error_code = 0
--    WHERE user_db_name = @user_db_name AND seq_no = @seq_no
--    
    SET @ret_code = @@ERROR
    IF @ret_code <> 0 RETURN
END

SET @ret_code = 0
SET NOCOUNT OFF
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO