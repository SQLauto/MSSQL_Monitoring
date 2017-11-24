SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_reprot_db_info
* 작성정보    : 2010-03-26 by choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    : 서버별 DB정보
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_report_db_info
	@server_id		int,
	@instance_id	int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @from_dt datetime, @to_dt datetime

select @from_dt = convert(nvarchar(10), max(reg_dt), 120)
from dbo.DATABASE_LIST with (nolock)
 where server_id = @server_id and instance_id = @instance_id
set @to_dt = dateadd(d, 1, @from_dt)

/* BODY */
select db_id, upper(db_name) as db_name
from dbo.DATABASE_LIST with (nolock) 
where server_id = @server_id and instance_id = @instance_id
    and reg_dt >= @from_dt and reg_dt < @to_dt
union all
select 0 , '!ALL'
order by db_name

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
