SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects
	   WHERE  name = N'up_DBA_SyncOperator' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_SyncOperator
GO

/************************************************************************  
* 프로시저명  : dbo.up_DBA_SyncOperator 
* 작성정보    : 2007-07-01 by ceusee (choi bo ra)
                AccountDB장비의 Tiger 에서 operator의 필요한 정보만 가져옴
* 관련페이지  :  
* 내용        :
* 수정정보    : 2007-07-31 by ceusee (choi bo ra), 현재 직원만 가져옴
                2007-08-27 by ceusee (choi bo ra), AccountDB에 셋팅된 정보 승계
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_SyncOperator
AS

/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* USER DECLARE */

/* BODY */
-- 퇴사자 삭제 처리

DELETE  dbo.OperatorSimple
FROM AccountDB.Tiger.dbo.Operator AS M JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 
WHERE   M.onoff = 'N' 

-- 신규 입사자 입력
-- DBA용 SMS 플래그 셋팅을 0 으로 한다. 

INSERT dbo.OperatorSimple (operatorNo, operatorId, sabun, temCode, operatorName, 
        HPNo, Email, jobFlag, dbFlag, backupFlag, logicFlag, HWFlag, registerDate, changeDate)
SELECT M.OId, M.OP_Id, M.sabun, 0, M.OP_NM, M.HP_No, M.Email, 0, 0, 0, 0, 0, M.Reg_DT, ISNULL(M.Chg_DT, GETDATE()) 
FROM AccountDB.Tiger.dbo.Operator AS M LEFT JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 
WHERE O.operatorId IS NULL AND M.onoff = 'Y'

IF @@ERROR <> 0 GOTO ERRORHANDLER

-- 수정사항 Update
UPDATE dbo.OperatorSimple
SET HPNo = M.HP_No,
    Email = M.Email,
    jobflag = OS.jobFlag,
    dbFlag = OS.dbFlag,
    logicFlag = OS.logicFlag,
    temCode = OS.temCode,
    backupFlag = OS.backupFlag,
    hwFlag = OS.hwFlag,
    changeDate = ISNULL(OS.changeDate,GETDATE())
FROM AccountDB.Tiger.dbo.Operator AS M JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo JOIN AccountDB.DBA.dbo.OperatorSimple AS OS 
    ON M.Oid = OS.operatorNo
WHERE ISNULL(M.CHG_DT,GETDATE()) <> ISNULL(O.changeDate,GETDATE()) AND M.onoff = 'Y'

IF @@ERROR <> 0 GOTO ERRORHANDLER

SET NOCOUNT OFF
RETURN


ERRORHANDLER:
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK
    RETURN 
END

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO