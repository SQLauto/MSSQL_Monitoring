SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_logshipping_copyfile_complete' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_logshipping_copyfile_complete
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_copyfile_complete 
* 작성정보    : 2007-08-02 choi bo ra (ceusee)
* 내용        : 파일 copy 완료 시간 Update
* 수정정보    : 
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_copyfile_complete
    @user_db_name       SYSNAME,
    @seq_no             INT,
    @log_file           NVARCHAR(200),
    @ret_code           INT OUTPUT
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET @ret_code = -1 
/* USER DECLARE */

/* BODY */
IF @user_db_name = '' OR @user_db_name IS NULL
BEGIN
    SET @ret_code = 11 -- 데이터베이스 명을 입력하세요.
    RETURN
END

UPDATE dbo.LOGSHIPPING_RESTORE_LIST
    SET copy_flag = 1,
        copy_end_time = GETDATE()
WHERE user_db_name = @user_db_name AND seq_no = @seq_no AND log_file = @log_file

SET @ret_code = @@ERROR
IF @ret_code <> 0 RETURN

SET NOCOUNT OFF
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO