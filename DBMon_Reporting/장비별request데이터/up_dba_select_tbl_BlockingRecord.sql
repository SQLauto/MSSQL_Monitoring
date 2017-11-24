SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_tbl_BlockingRecord
* 작성정보    : 2010-01-05 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_tbl_BlockingRecord
     @from_rec_dt       datetime,
     @to_rec_dt         datetime
     
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @from_dt datetime, @to_dt datetime
declare @svr_id tinyint
set @svr_id = 10 -- gmkt2008


/* BODY */
if @from_rec_dt is null or @to_rec_dt is null
begin
     set @from_dt  = dateadd(mi, -10, getdate())
    set @to_dt = dateadd(mi, 1, getdate())
    
end

select 
    @svr_id svr_id
    ,session_id
    ,blocking_session_id
    ,is_blocker
    ,db_name
    ,object_name
    ,program_name
    ,query_text
    ,total_elapsed_time
    ,reads
    ,writes
    ,logical_reads
    ,scheduler_id
    ,wait_type
    ,wait_resource
    ,open_transaction_count
    ,login_name
    ,host_name
    ,rec_dt
from   tbl_BlockingRecord with (nolock) 
where rec_dt >= @from_dt and rec_dt < @to_dt



RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO