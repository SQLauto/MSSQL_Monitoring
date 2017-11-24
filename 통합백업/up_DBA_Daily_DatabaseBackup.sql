SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_DBA_Daily_DatabaseBackup 
* 작성정보    : 2007-08-11
* 관련페이지  :  
* 내용        : 일 마다 Full 데이터베이스 백업, Native/LiteSpeed
* 수정정보    : 2007-08-28 백업파일 일자 부분 수정
                2008-06-21 DIFF 백업 확장자 변경
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_Daily_DatabaseBackup
     @user_db_name          SYSNAME,
     @delete_flag           TINYINT = 1,        --1:delete, 2:no delete
     @backup_type           TINYINT = 2,        --1: Native, 2:LiteSpeed
     @backup_flag           VARCHAR(4),         --LOG | DB | DIFF
     @file_dir              NVARCHAR(256) = NULL,
     @user_threads          SMALLINT = 16,
     @user_transfersize     INT = 2097152,
     @user_logging          INT = 2,            --SQLLitespeed logging level ( 0 | 1 | 2 )
     @verify                BIT = 1,            --verify backup 1:verify, 2:no verify
     @ret_code              INT OUTPUT
     
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET @ret_code = -1
/* USER DECLARE */
DECLARE  @get_date			DATETIME
DECLARE  @backup_day		NVARCHAR(12)
DECLARE  @backup_full_name  NVARCHAR(300)
DECLARE  @backup_type_name  NVARCHAR(15)
DECLARE  @str_sql			NVARCHAR(100)
SET @get_date = GETDATE()
SET @backup_day =  CONVERT(nvarchar(8),GETDATE(),112) 
IF LEN(CONVERT(NVARCHAR(2),DATEPART(HH, GETDATE())) )  = 1
  SET @backup_day = @backup_day + '0' 
SET @backup_day = @backup_day +  CONVERT(NVARCHAR(2),DATEPART(HH, GETDATE()))

IF LEN( CONVERT(NVARCHAR(2),DATEPART(MI, GETDATE())) ) = 1
    SET @backup_day = @backup_day + '0' 
SET @backup_day = @backup_day  + CONVERT(NVARCHAR(2),DATEPART(MI, GETDATE()))


/* BODY */

-- check database exists and is online
SET @user_db_name = UPPER(@user_db_name)
IF (DB_ID(@user_db_name) IS NULL) OR (DATABASEPROPERTYEX(@user_db_name,'Status')<>'ONLINE')
BEGIN                   				
	RAISERROR('Database %s is invalid or database status is not ONLINE',16,1,@user_db_name)
	SET @ret_code = 11
	RETURN		
END

-- check @backup_flag is valid
IF UPPER(@backup_flag) NOT IN ('LOG','DB','DIFF')
BEGIN                   				
	RAISERROR('%s is not a valid option for @backup_flag',16,1,@backup_flag)
	SET @ret_code = 15
	RETURN		
END

-- check recovery mode is correct if trying log backup
IF (DATABASEPROPERTYEX(@user_db_name,'Recovery')='SIMPLE' and @backup_flag = 'LOG')
BEGIN                   				
	RAISERROR('%s is not a valid option for database %s because it is in SIMPLE recovery mode',16,1,@backup_flag, @user_db_name)
	SET @ret_code = 16
	RETURN	
END

-- check file dir

IF @file_dir = '' OR @file_dir IS NULL
BEGIN
    SET @ret_code = 12    -- 디렉토리 경로 입력
    RETURN
END
ELSE
BEGIN
   IF CHARINDEX(CHAR(32),@file_dir)>0
   BEGIN
      	RAISERROR('The backup folder path "%s" cannot contain spaces',16,1, @file_dir)
        SET @ret_code = 12
      	RETURN	
   END
END

-- check backup type
IF (@backup_Type <> 1 AND @backup_Type <> 2)
BEGIN
    SET @ret_code =13 -- 트랜젝션로그 유형이 잘 못 되었습니다.
    RETURN
END


-- set file name
IF RIGHT(@file_dir,1) <> '\' SET @file_dir = @file_dir + '\'

SELECT @backup_full_name = @file_dir + REPLACE(@user_db_name,' ','_') +
   CASE WHEN UPPER(@backup_flag) = 'DB'   THEN '_DB_'
        WHEN UPPER(@backup_flag) = 'DIFF' THEN '_DIFF_'
        WHEN UPPER(@backup_flag) = 'LOG'  THEN '_TLOG_'  END +
   CASE WHEN @backup_Type = 2 THEN 'LiteSpeed_' + @backup_day ELSE @backup_day END  +
   CASE WHEN UPPER(@backup_flag) = 'LOG' THEN '.TRN' 
		WHEN UPPER(@backup_flag) ='DIFF' THEN '.DIFF' ELSE '.BAK' END
    
-- 전일자 백업 파일 삭제
IF @delete_flag = 1
BEGIN
    
    SELECT @str_sql = N'EXEC master..xp_cmdshell  ''DEL ' + @file_dir  + @user_db_name +
         CASE WHEN UPPER(@backup_flag) = 'DB'   THEN '_DB*.BAK'''
        WHEN UPPER(@backup_flag) = 'DIFF' THEN '_DIFF*.BAK'''
        WHEN UPPER(@backup_flag) = 'LOG'  THEN '_TLOG*.TRN'''  END  

    EXEC sp_executesql @str_sql
    
    SET @ret_code = @@ERROR
    IF @ret_code <> 0 RETURN

END


--- backup action

IF @backup_type = 1   -- Native BACKUP
BEGIN
    IF UPPER(@backup_flag) = 'DB'
    BEGIN
        BACKUP DATABASE @user_db_name
    	    TO  DISK = @backup_full_name
        WITH 
        	INIT,  
        	NAME = 'Full Database Backup',
			STATS = 20
        
        SET @ret_code = @@ERROR
        IF @ret_code <> 0 RETURN
    END   
    ELSE IF UPPER(@backup_flag) = 'DIFF'
    BEGIN
        BACKUP DATABASE @user_db_name
    	    TO  DISK = @backup_full_name
        WITH 
        	NOINIT,  
        	NAME = 'DIFF Database Backup',
			STATS = 20,
			DIFFERENTIAL
			
    END
    ELSE IF UPPER(@backup_flag) = 'LOG'
    BEGIN
       BACKUP LOG @user_db_name
		  TO DISK = @backup_full_name
	   WITH NOINIT,
			STATS = 20
		  
    END
    
    -- 확인
    IF @verify = 1  
    BEGIN
        RESTORE VERIFYONLY FROM DISK = @backup_full_name

        SET @ret_code = @@ERROR
        IF @ret_code <> 0 RETURN
    END
    
END   	
ELSE IF @backup_type = 2  -- LiteSpeed
BEGIN 
	IF UPPER(@backup_flag) = 'DB'
    BEGIN
        IF (@user_threads IS NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @init = 1,
                                                           @backupname ='FULL Database Backup',
                                                           @buffercount = 20,
                                                           @logging = @user_logging                            
        END
		ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @init = 1,
                                                           @backupname ='FULL Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @threads = @user_threads,
                                                           @logging = @user_logging
       END
	   ELSE IF (@user_threads IS NULL AND @user_transfersize IS NOT NULL)
       BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @init = 1,
                                                           @backupname ='FULL Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging
      END
	  ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NOT NULL)
      BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @init = 1,
                                                           @backupname ='FULL Database Backup',
                                                           @buffercount = 20,  
                                                           @threads = @user_threads,                                                         
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging
      END
	END  -- DB
   --************************
   -- DIFFERENTIAL BACKUP
   --***********************
	ELSE IF UPPER(@backup_flag) = 'DIFF'
	BEGIN
		IF (@user_threads IS NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='DIFF Database Backup',
                                                           @buffercount = 20,
                                                           @logging = @user_logging, 
                                                           @with = 'DIFFERENTIAL'                           
        END
		ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='DIFF Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @threads = @user_threads,
                                                           @logging = @user_logging,
                                                           @with = 'DIFFERENTIAL'
       END
       ELSE IF (@user_threads IS NULL AND @user_transfersize IS NOT NULL)
       BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='DIFF Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging,
                                                           @with = 'DIFFERENTIAL'
      END
      ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NOT NULL)
      BEGIN
            EXEC @ret_code = master.dbo.xp_backup_database @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='DIFF Database Backup',
                                                           @buffercount = 20,  
                                                           @threads = @user_threads,                                                         
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging,
                                                           @with = 'DIFFERENTIAL'
      END
	END  -- DIFF
   --************************
   --       LOG BACKUP
   --***********************
   ELSE IF UPPER(@backup_flag) = 'LOG'
   BEGIN
		IF (@user_threads IS NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_log @database = @user_db_name,
                                                       @filename = @backup_full_name,
                                                       @backupname ='LOG Database Backup',
                                                       @buffercount = 20,
                                                       @logging = @user_logging 
                                                                                 
        END
		ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NULL)
        BEGIN
            EXEC @ret_code = master.dbo.xp_backup_log @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='LOG Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @threads = @user_threads,
                                                           @logging = @user_logging
                                                          
       END
       ELSE IF (@user_threads IS NULL AND @user_transfersize IS NOT NULL)
       BEGIN
            EXEC @ret_code = master.dbo.xp_backup_log @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='LOG Database Backup',
                                                           @buffercount = 20,                                                           
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging
                                                          
      END
      ELSE IF (@user_threads IS NOT NULL AND @user_transfersize IS NOT NULL)
      BEGIN
            EXEC @ret_code = master.dbo.xp_backup_log @database = @user_db_name,
                                                           @filename = @backup_full_name,
                                                           @backupname ='LOG Database Backup',
                                                           @buffercount = 20,  
                                                           @threads = @user_threads,                                                         
                                                           @maxtransfersize = @user_transfersize,
                                                           @logging = @user_logging
                                                          
      END
	END --LOG

	
	IF @ret_code <> 0 RETURN
	IF @verify = 1
    BEGIN
        EXEC @ret_code = master.dbo.xp_restore_verifyonly 
    			@filename = @backup_full_name
    	IF @ret_code <> 0 RETURN
    END 
	
END

SET @ret_code = 0
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO