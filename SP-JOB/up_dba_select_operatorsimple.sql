SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_operatorsimple 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : OperatorSimple 테이블의 operatrNo 조회
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo
    ,jobflag 
    ,dbFlag
    ,logicFlag 
    ,temCode
    ,backupFlag 
    ,hwFlag 
    ,changeDate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO