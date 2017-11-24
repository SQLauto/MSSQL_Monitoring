SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_update_operatorsimple 
* �ۼ�����    : 2008-06-30
* ����������  :  
* ����        : Ÿ���� �Ǵ� Operatorsiple ���̺� ���泻�� ����
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_update_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
UPDATE dbo.OperatorSimple
SET HPNo = T.HPNO,
    Email = T.EMAIL,
    jobflag = T.JOBFLAG,
    dbFlag = T.DBFLAG,
    logicFlag = T.logicFlag,
    temCode = T.temCode,
    backupFlag = T.backupFlag,
    hwFlag = T.hwFlag,
    changedate= ISNULL(T.chg_dt,GETDATE())
FROM dbo.DBA_OPERATOR_TEMP AS T JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON T.Oid = O.operatorNo 

RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO