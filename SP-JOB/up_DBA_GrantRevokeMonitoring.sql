SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_GrantRevokeMonitoring' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_GrantRevokeMonitoring
GO

/*************************************************************************  
* ���ν�����  : dbo.up_DBA_GrantRevokeMonitoring 
* �ۼ�����    : 2007-07-13 by choi bo ra (ceusee)
* ����������  :  
* ����        : ����/���� ����͸��� �ϱ����� ���� ����
                jobFlag : 1
                dbFlag : 2
                backupFlag : 3
                logicFlag : 4
                HWFlag : 5
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_GrantRevokeMonitoring
    @operatorNo         INT = 0,
    @workFlag           TINYINT = 1, 
    @grantFlag          TINYINT = 1
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
IF @workFlag = 1 -- Job
BEGIN
    
    UPDATE OperatorSimple
    SET jobFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
    IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 2 --DB
BEGIN
    
    UPDATE OperatorSimple
    SET dbFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
    IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 3 --DB
BEGIN
    
    UPDATE OperatorSimple
    SET backupFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 4 --logicFlag
BEGIN
    
    UPDATE OperatorSimple
    SET logicFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
ELSE IF @workFlag = 5 --HWFlag
BEGIN
    
    UPDATE OperatorSimple
    SET HWFlag = @grantFlag
    WHERE operatorNo = @operatorNo
    
     IF @@ERROR <> 0 RETURN

END
SET NOCOUNT OFF
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

