SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure sp_what @spid smallint
as

set nocount on
if len(@spid) = 0 
	print 'SPID를 입력해주십시요'
else
	declare @handle binary(20)
	select @handle = sql_handle from sysprocesses where spid = @spid
	select * from ::fn_get_sql(@handle) 
set nocount off

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
