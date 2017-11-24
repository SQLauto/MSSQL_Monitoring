/*----------------------------------------------------
    Date    : 2008-07-02
    Note    : OperatorSimple Sync�� ���� ����
    No.     :
*----------------------------------------------------*/
use dba
go


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* ���ν�����  : dbo.up_dba_select_operator 
* �ۼ�����    : 2008-06-30 by choi bo ra
* ����������  :  
* ����        : Accountdb�� �ִ� tiger�� operator�� select �Ѵ�.
* ��������    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_operator
    @onoff   char(1)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT M.OId, M.OP_Id, M.sabun, M.OP_NM, M.HP_No, M.Email, M.Reg_DT, ISNULL(M.Chg_DT, GETDATE()) as chg_dt
FROM Tiger.dbo.Operator AS M WITH (NOLOCK) 
WHERE M.onoff = @onoff
ORDER BY M.OId


RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO