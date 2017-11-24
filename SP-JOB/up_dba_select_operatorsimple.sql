SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
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