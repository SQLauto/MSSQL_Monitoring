SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_delete_operatorsimple 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : ����� ���� ����
* ��������    :
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