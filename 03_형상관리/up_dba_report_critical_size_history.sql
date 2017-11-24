SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_critical_size_history
* 작성정보    : 2010-
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_report_critical_size_history 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
DECLARE @reg_date datetime
SET @reg_date = dateadd(m,-1,convert(datetime, convert(nvarchar(10), getdate(), 121)))

select b.server_name, a.reg_dt, a.db_id, d.db_name,SUM(a.size) as [database_size], SUM(size)-SUM(a.usage) as [unallocated space]
from DATABASE_FILE_LIST as a with(nolock)  
	join serverinfo  as b with (nolock) on a.server_id = b.server_id
	join database_list as d with(nolock) on a.server_id = d.server_id and a.db_id = d.db_id
			and d.reg_dt >= @reg_date
	join CRITICAL_SERVER as c with(nolock) on a.server_id = c.server_id and d.db_name = c.db_name
where a.reg_dt >= @reg_date
	and a.filegroup is not null
group by b.server_name, a.reg_dt,a.db_id, d.db_name
ORDER BY b.server_name, a.reg_dt,d.db_name


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
