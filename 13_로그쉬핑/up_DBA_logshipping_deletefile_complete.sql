SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_logshipping_deletefile_complete' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_deletefile_complete
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_deletefile_complate 
* 작성정보    : 2007-08-07
* 관련페이지  :  
* 내용        : 카피한 파일을 복원완료 했으면 삭제하고 완료 처리
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_deletefile_complete
    @user_db_name       SYSNAME,
    @seq_no             INT,
    @log_file           NVARCHAR(200),
    @ret_code           INT OUTPUT
     
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
SET @ret_code = -1
/* BODY */
IF @user_db_name = '' OR @user_db_name IS NULL
BEGIN
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.
    RETURN
END


UPDATE dbo.LOGSHIPPING_RESTORE_LIST
    SET delete_flag = 1,
        delete_time = GETDATE()
WHERE user_db_name = @user_db_name AND seq_no = @seq_no AND log_file = @log_file

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN

SET @ret_code = 0

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO