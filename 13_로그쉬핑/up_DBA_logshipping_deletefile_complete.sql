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
* ���ν�����  : dbo.up_DBA_logshipping_deletefile_complate 
* �ۼ�����    : 2007-08-07
* ����������  :  
* ����        : ī���� ������ �����Ϸ� ������ �����ϰ� �Ϸ� ó��
* ��������    :
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
    SET @ret_code = 11 -- �����ͺ��̽� ���� �Է��ϼ���.
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