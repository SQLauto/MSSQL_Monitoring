SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_loghsipping_restore_complete' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_loghsipping_restore_complete
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_loghsipping_restore_complete 
* 작성정보    : 2007-08-07 choi bo ra (ceusee)
* 관련페이지  :  
* 내용        : 복원 완료한 파일 정보
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_loghsipping_restore_complete
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
WHERE user_db_name = @user_db_name AND delete_flag = 0 AND restore_flag= 1 

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


