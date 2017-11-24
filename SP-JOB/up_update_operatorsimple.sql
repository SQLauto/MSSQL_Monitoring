SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_update_operatorsimple 
* 작성정보    : 2008-06-30
* 관련페이지  :  
* 내용        : 타켓이 되는 Operatorsiple 테이블에 변경내역 저장
* 수정정보    :
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