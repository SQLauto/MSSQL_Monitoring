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
* ���ν�����  : dbo.up_DBA_DeleteEMSSendMaster 
* �ۼ�����    : 2007-07-06 by ceusee (choi bo ra)
* ����������  :  
* ����        : ���� ó�� ���۵� �ð��� ���� �۾� �����Ѵ�.
* ��������    :
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
-- �۾��� �����ϴ� ���� 0 ~ 1�� ���̿� ���� �۾�, 2Ʋ ������ ������ ����
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