SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_report_errlog
* 작성정보    : 2010-
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_errlog 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_date datetime
/* BODY */

SET @reg_date = convert(datetime, convert(nvarchar(10), getdate(), 121))

select b.server_name, case when e.log_type = 'S' then 'SQL' else 'Agent' end as type 
	, e.log_date, e.process_info, e.log_text
from SQL_ERROR_LOG  as e with (nolock) 
	join  CRITICAL_SERVER as c with(nolock) on e.server_id = c.server_id 
	join serverinfo  as b with (nolock) on e.server_id = b.server_id
where e.log_date >= @reg_date
	and (e.process_info !='Backup' and e.process_info != '백업')
order by b.server_name, e.log_date 


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
