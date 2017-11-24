SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_restore' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_restore
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_restore 
* 작성정보    : 2007-08-03 choi bo ra(ceusee)
* 관련페이지  :  
* 내용        : 트랜젝션 로그 파일 복원
* 수정정보    : 2007-08-20 종료일자 수정
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_restore
    @user_db_name       SYSNAME, 
    @file_dir           NVARCHAR(256) = NULL,
    @standy_dir         NVARCHAR(256),
    @hour               INT,           -- 1:홀수시간, 2:짝수시간
    @ret_code           INT  OUTPUT
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET @ret_code = -1

/* USER DECLARE */
DECLARE @min_seq_no             INT
DECLARE @max_seq_no             INT
DECLARE @restore_type			TINYINT
DEClARE @dtGetDate              DATETIME
DECLARE @log_file_name          NVARCHAR(200)
DECLARE @restore_full_name      NVARCHAR(256)
DECLARE @standy_file_name       NVARCHAR(256)
SET @min_seq_no = 0
SET @max_seq_no = 0


/* BODY */
SET @user_db_name = UPPER(@user_db_name)
IF @user_db_name IS NULL
BEGIN
     SET @ret_code = 11 -- 데이터베이스 명 입력
     RETURN
END

IF @file_dir = '' OR @file_dir = NULL
BEGIN
    SET @ret_code = 12    -- 디렉토리 경로 입력
    RETURN
END

IF @standy_dir = '' OR @standy_dir = NULL
BEGIN
    SET @ret_code = 14    -- 디렉토리 경로 입력
    RETURN
END

/*
IF @hour <> 1 AND @hour <> 2
BEGIN
    SET @ret_code = 15   -- 홀수/짝수시간이 아니면
    RETURN
END
*/

-- 실행될 시간 체크
IF @hour = 1  AND (DATEPART(HH,GETDATE())%2) = 0  -- 홀수시간
BEGIN
    SET @ret_code = 0
    RETURN
END
ELSE IF @hour = 2  AND (DATEPART(HH,GETDATE())%2) = 1  -- 짝수시간
BEGIN
    SET @ret_code = 0
    RETURN
END

SET @standy_file_name = 'STANDBY= N''' + @standy_dir + '\' + @user_db_name + '\' + @user_db_name + '_undo.ldf'''

-- Step 1. 복원할 파일 정보 확인
SELECT @min_seq_no = MIN(seq_no), @max_seq_no = MAX(seq_no) 
FROM dbo.LOGSHIPPING_RESTORE_LIST  WITH (NOLOCK)
WHERE user_db_name = @user_db_name AND restore_flag <> 1  AND copy_flag = 1  AND restore_end_time is null

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN

-- Step 2. 복원
IF @min_seq_no <>  0 AND  @max_seq_no <>  0
BEGIN
    WHILE (@min_seq_no <= @max_seq_no)
    BEGIN
      
      
    IF @hour = 1  AND (DATEPART(HH,GETDATE())%2) = 0  -- 홀수시간
    BEGIN
        SET @ret_code = 0
        BREAK
    END
    ELSE IF @hour = 2  AND (DATEPART(HH,GETDATE())%2) = 1  -- 짝수시간
    BEGIN
        SET @ret_code = 0
        BREAK
    END
      
        -- 50분 이상이면 멈춘다.
       IF DATEPART(MI,GETDATE()) >= 50 BREAK;
        
        SELECT @log_file_name = log_file, @restore_type = restore_type FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK) 
            WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no
        SET @ret_code = @@ERROR
        IF @ret_code <> 0 BREAK;
        
	
        IF @log_file_name <> '' OR @log_file_name  IS NOT NULL
        BEGIN
            SET @restore_full_name = @file_dir + '\' + @user_db_name + '\' + @log_file_name
            SET @dtGetDate = GETDATE()
         

            UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_start_time =@dtGetDate 
            WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no
           
           SET @ret_code = @@ERROR
           IF @ret_code <> 0 BREAK;
           
           -- 사용자 Kill
           EXEC master.dbo.sp_dba_process_user_kill @user_db_name
           SET @ret_code = @@ERROR
           IF @ret_code <> 0 BREAK;

			IF @restore_type = 1
			BEGIN

			RESTORE LOG @user_db_name  
				FROM DISK = @restore_full_name  
				WITH STANDBY=@standy_file_name  

			SET @ret_code = @@ERROR
			END
			ELSE IF @restore_type = 2
			BEGIN
			 
			 EXEC @ret_code = master.dbo.xp_restore_log   
					@database = @user_db_name,
					@filename = @restore_full_name,
					@logging = 2, 
					@with =  @standy_file_name  
		    END
			
			IF @ret_code <> 0   -- 에러
			BEGIN
				UPDATE dbo.LOGSHIPPING_RESTORE_LIST 
                SET restore_flag = 2, 
                    --restore_end_time = GETDATE(), 
                    --restore_duration = DATEDIFF(ss, @dtGetDate, GETDATE()),
                    error_code = @ret_code         
                WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no 
                
				BREAK; --LOOP 빠져나감 
				


			END
			ELSE   -- 성공
			BEGIN
				UPDATE dbo.LOGSHIPPING_RESTORE_LIST SET restore_flag = 1, restore_end_time = GETDATE(), 
						restore_duration = DATEDIFF(ss, @dtGetDate, GETDATE()), error_code = 0
				WHERE user_db_name = @user_db_name AND seq_no = @min_seq_no
			    
				SET @ret_code = @@ERROR
				IF @ret_code <> 0 RETURN
			END
		END  
        
        SET @min_seq_no = @min_seq_no + 1
 
    END  --Loop End
END
    
SET @ret_code = 0
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO