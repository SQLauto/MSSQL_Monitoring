
/*************************************************************************  
* ���ν�����  : dbo.up_DBA_logshipping_status 
* �ۼ�����    : 2007-08-12
* ����������  :  
* ����        : �α׽����� �ϸ鼭 �����ͺ��̽� ���� ���°� 50���� �Ѿ�� ����
                ���̸� �ȵ�, Check
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_logshipping_status
     @user_db_name      SYSNAME, 
     @RESTORE_YN        CHAR(1) OUTPUT
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
SET @RESTORE_YN = 'N'

/* BODY */
DECLARE @RESULT SQL_VARIANT
SELECT @RESULT = DATABASEPROPERTYEX( @user_db_name , 'IsInStandBy' )
IF @RESULT = 1
BEGIN 

	SET @RESTORE_YN = 'N' -- ������
	RETURN 0
END
ELSE
BEGIN
	SET @RESTORE_YN = 'Y' 

	RETURN 0
END
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO