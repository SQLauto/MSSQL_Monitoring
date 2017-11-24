
/*************************************************************************  
* 프로시저명  : dbo.up_DBA_logshipping_status 
* 작성정보    : 2007-08-12
* 관련페이지  :  
* 내용        : 로그쉬핑을 하면서 데이터베이스 들의 상태가 50분이 넘어서도 복원
                중이면 안됨, Check
* 수정정보    :
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

	SET @RESTORE_YN = 'N' -- 복원중
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