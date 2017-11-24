SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* ���ν�����  : dbo.up_conf_IACTransMasterSelect
* �ۼ�����    : 2010-11-11 by choi bo ra
* ����������  : ���� �̰� ��å ���̺�
* ����        : exec up_conf_IACTransMasterSelect 'gendb1'
* ��������    :
**************************************************************************/
ALTER PROCEDURE dbo.up_conf_IACTransMasterSelect
    @from_server    nvarchar(50) = ''
   ,@db_name        nvarchar(20) = ''
   ,@table_name     sysname = ''
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select from_server, from_db, from_table, 
    to_server, to_db, to_table,
    case when status = 'D' then '����' else '�̰�' end status,
   case when unit = 'D' then '��' case when unit = 'M' then '��' end as unit,
    period, trans_column, sp_name, job_name,
    mgr_team, mgr_name
from dbo.iac_trans_master with (nolock)
  where from_server = case when @from_server = '' then from_server else @from_server end
    and from_db = case when @db_name = '' then from_db else @db_name end 
    and from_table = case when @table_name = '' then from_table else @table_name end
order by from_server

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


��󼭹�
����DB
From Table