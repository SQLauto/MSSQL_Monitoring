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
* ���ν�����  : dbo.up_DBA_loghsipping_restore_complete 
* �ۼ�����    : 2007-08-07 choi bo ra (ceusee)
* ����������  :  
* ����        : ���� �Ϸ��� ���� ����
* ��������    :
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
    SET @ret_code = 11 -- �����ͺ��̽� ���� �Է��ϼ���.
    RETURN
END

-- ���� copy�ؾ��ϰ� ������ �ȵȰ�
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


