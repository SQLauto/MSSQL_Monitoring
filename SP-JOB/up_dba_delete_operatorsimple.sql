SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_delete_operatorsimple 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : 퇴사한 직원 삭제
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_delete_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
/* BODY */
DELETE  OperatorSimple
FROM DBA.dbo.DBA_OPERATOR_TEMP AS M WITH (NOLOCK) JOIN dbo.OperatorSimple AS O WITH (NOLOCK)
    ON M.Oid = O.operatorNo 


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO