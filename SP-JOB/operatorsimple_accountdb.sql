/*----------------------------------------------------
    Date    : 2008-07-02
    Note    : OperatorSimple Sync를 위한 내역
    No.     :
*----------------------------------------------------*/
use dba
go


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_operator 
* 작성정보    : 2008-06-30 by choi bo ra
* 관련페이지  :  
* 내용        : Accountdb에 있는 tiger의 operator를 select 한다.
* 수정정보    :
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