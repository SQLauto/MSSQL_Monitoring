SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_target_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : update �ؾ��� 
                OperatorSimple ���̺��� operatrNo ��ȸ
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_target_operatorsimple
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT operatorNo, changedate
FROM DBA.dbo.OperatorSimple with (nolock)
ORDER BY operatorNo

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO