SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_loghsipping_restore_file' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_loghsipping_restore_file
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_loghsipping_restore_file 
* 작성정보    : 2007-08-02 choi bo ra (ceusee)
* 관련페이지  :  
* 내용        : 복원할 파일 정보 가져오기
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_loghsipping_restore_file
    @user_db_name       SYSNAME,
    @seq_no             INT OUTPUT,
    @log_file           NVARCHAR(200) OUTPUT, 
    @ret_code           INT OUTPUT         
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
SET @log_file =  ''
SET @ret_code =  -1

/* BODY */
IF @user_db_name = '' OR @user_db_name IS NULL
BEGIN
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.
    RETURN
END

-- 파일 copy해야하고 복원도 안된것
SELECT @seq_no = ISNULL(MIN(seq_no),0)
FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)
WHERE user_db_name = @user_db_name AND copy_flag = 0 AND restore_flag= 0 

SET @ret_code = @@ERROR
IF @ret_code <> 0  RETURN

IF @seq_no <> 0 
BEGIN
    SELECT @log_file = log_file
    FROM dbo.LOGSHIPPING_RESTORE_LIST WITH (NOLOCK)
    WHERE user_db_name = @user_db_name AND seq_no = @seq_no
END

SET @ret_code = @@ERROR
IF @ret_code <> 0  RETURN

SET @ret_code= 0 
SET NOCOUNT OFF
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


-- 테이블 변경
--INSERT INTO LOGSHIPPING_RESTORE_LIST
--SELECT 'SETTLE', seqno, 0, log_file, 
--        CASE  WHEN copy_y = 'Y' THEN 1
--              WHEN copy_y = 'N' THEN 2
--              WHEN copy_y is null THEN 0
--        END copy_flag,
--        copy_end_time,
--        CASE WHEN backup_type = 'N' THEN 1
--             WHEN backup_type = 'L' THEN 2
--        END restore_type,
--        CASE  WHEN restore_y = 'Y' THEN 1
--              WHEN restore_y = 'N' THEN 2
--              WHEN restore_y is null THEN 0
--        END restore_flag,
--        start_time , end_time, duration, 
--        CASE  WHEN delete_y = 'Y' THEN 1
--              WHEN delete_y = 'N' THEN 2
--              WHEN delete_y is null THEN 0
--        END delete_y,
--        delete_time, isnull(err, 0), copy_end_time
--FROM logshipping_list_settle
