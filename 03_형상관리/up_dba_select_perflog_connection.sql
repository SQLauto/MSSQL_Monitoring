SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_perflog_connection
* 작성정보    : 2010-04-20 by choi bo ra
* 관련페이지  : 
* 내용        : 성능 couner 수집하는 연결정보
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_perflog_connection 
	@site_gn char(1)
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select distinct p.server_id, s.server_name,i.instance_name, s.server_public_ip, i.instance_port
from SERVER_PERFLOG as p with (nolock)
join INSTANCE as i with (nolock) on p.server_id = i.server_id
join serverinfo as s with (nolock) on p.server_id = s.server_id
where s.site_gn = @site_gn

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
