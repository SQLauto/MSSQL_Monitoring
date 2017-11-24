SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_perflog_dir
* 작성정보    : 2010-04-20 by choi bo ra
* 관련페이지  : 
* 내용        : 서버별 경로 내역
* 수정정보    : exec up_dba_select_perflog_dir 11
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_select_perflog_dir 
		@server_id		int
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select
	p.perflog_name , p.perflog_perfix, p.perflog_dir
from SERVER_PERFLOG as p with (nolock)
WHERE p.server_id = @server_id
order by p.server_id, p.perflog_name
	
RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
