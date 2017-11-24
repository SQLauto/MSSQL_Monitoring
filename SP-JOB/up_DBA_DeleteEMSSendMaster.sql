SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_DeleteEMSSendMaster' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_DeleteEMSSendMaster
GO

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_DeleteEMSSendMaster 
* 작성정보    : 2007-07-06 by ceusee (choi bo ra)
* 관련페이지  :  
* 내용        : 매일 처음 시작될 시간에 삭제 작업 진행한다.
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_DeleteEMSSendMaster
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */
DECLARE @dtGetDate      DATETIME
DECLARE @hour           INT
DECLARE @strGetDate     NVARCHAR(10)
SET @dtGetDate = GETDATE()
SET @hour = DATEPART( hh, @dtGetdate)
SET @strGetDate = CONVERT(NVARCHAR(10),getdate(),120)

/* BODY */
-- Step 1
-- 작업이 시작하는 오전 0 ~ 1시 사이에 삭제 작업, 2틀 전보다 작은것 제거
IF @hour >= 0 AND @hour < 1         
BEGIN
    DELETE EMSSendMaster WHERE sendFlag = 2 AND changeDate < DATEADD(DD,-2, CONVERT(datetime, @strGetDate , 120))
    IF @@ERROR <> 0 GOTO ERRORHANDLER
END

SET NOCOUNT OFF
RETURN

ERRORHANDLER:
BEGIN
    RETURN 
END

GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO