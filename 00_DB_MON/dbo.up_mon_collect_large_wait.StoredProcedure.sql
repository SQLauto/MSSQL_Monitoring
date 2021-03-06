USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_large_wait]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_large_wait
* 작성정보    : 2010-04-07 by choi bo ra
* 관련페이지  : 
* 내용        : large wait
* 수정정보    : 2014-04-28 BI/DW/GCENTERDB 임계치 3시간으로 변경. 디폴트는 1시간 by Seo Eun Mi
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_large_wait] 
	@wait_duration_ms   int		 = 100, 
	@site				char(1)	 = 'G'

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime
DECLARE @term int 
/* BODY */
exec UP_SWITCH_PARTITION  @table_name = 'DB_MON_LARGE_WAIT',@column_name = 'reg_date'

set @reg_date = getdate()

IF (@@SERVERNAME LIKE 'BI%') OR (@@SERVERNAME LIKE 'DW%') OR (@@SERVERNAME = 'GCENTERDB') 
	set @term = 180*3600000
ELSE
	set @term = 3600000

--INSERT INTO dbo.DB_MON_LARGE_WAIT
--	( 
--    reg_date     
-- ,   session_id  
-- ,   exec_context_id     
-- ,   wait_type    
-- ,   last_wait_type    
-- ,   wait_duration_ms  
-- ,   status     
-- ,   cpu_time   
-- ,   blocking_session_id  
-- ,   blocking_task_address   
-- ,   db_name    
-- ,   scheme_name    
-- ,   object_name    
-- ,   query_text    
-- ,   login_name    
-- ,   host_name     
-- ,   program_name    
-- ,   login_time    
-- ,   reads     
-- ,   writes   
-- ,   logical_reads     
-- ,   resource_description 
-- )
SELECT
	 @reg_date reg_date
	, tsk.session_id
	, tsk.exec_context_id
	, tsk.wait_type
	, r.last_wait_type
	, tsk.wait_duration_ms
	, r.status
	, r.cpu_time
	, tsk.blocking_session_id
	, tsk.blocking_task_address
	,db_name(qt.dbid) as db_name
    ,object_schema_name(qt.objectid, qt.dbid) as schema_name
    ,object_name(qt.objectid, qt.dbid)  as object_name
    ,CASE WHEN   r.statement_end_offset = -1 and ( (r.statement_start_offset / 2)  > DATALENGTH (isnull(qt.text, '') ) )
    THEN  convert(varchar(4000), 
    		   substring(isnull(qt.text, '') 
    			, 1, ( ( DATALENGTH (isnull(qt.text, '') ) - 1 )/2 ) + 1 ) )
    ELSE  convert(varchar(4000), substring(isnull(qt.text, '') 
    	, (r.statement_start_offset / 2) + 1
    	, (( case when r.statement_end_offset = -1 then DATALENGTH (isnull(qt.text, '') ) else r.statement_end_offset end	
    			- r.statement_start_offset ) /2 ) + 1) )
    END  as query_text
	,s.login_name
	,s.host_name
	,s.program_name
	,s.login_time
	,r.reads
	,r.writes
	,r.logical_reads
	,tsk.resource_description
into #t1
from sys.dm_os_waiting_tasks as tsk with (nolock)
	inner join sys.dm_exec_requests as r with (nolock) on tsk.session_id = r.session_id
	inner join sys.dm_exec_sessions  as s with (nolock)  on  tsk.session_id = s.session_id
	cross apply sys.dm_exec_sql_text(r.sql_handle) as qt  
where tsk.session_id > 50  and s.is_user_process  = 1
and tsk.wait_type <> 'WAITFOR'
and tsk.wait_duration_ms >= @wait_duration_ms
order by tsk.wait_duration_ms desc


INSERT INTO dbo.DB_MON_LARGE_WAIT
	( 
    reg_date     
 ,   session_id  
 ,   exec_context_id     
 ,   wait_type    
 ,   last_wait_type    
 ,   wait_duration_ms  
 ,   status     
 ,   cpu_time   
 ,   blocking_session_id  
 ,   blocking_task_address   
 ,   db_name    
 ,   scheme_name    
 ,   object_name    
 ,   query_text    
 ,   login_name    
 ,   host_name     
 ,   program_name    
 ,   login_time    
 ,   reads     
 ,   writes   
 ,   logical_reads     
 ,   resource_description 
 )
select * from #T1


-- 1시간 이상 문자 발송
if  ( datepart(hh, @reg_date) >= 7 and datepart(hh, @reg_date) <= 23 )
begin
        declare @session_id int , @rowcount int
        declare @msg varchar(80), @i int
        
        declare @large_wait table ( seqno  int identity(1,1) ,  session_id int)
        
       
        insert into @large_wait
        select  distinct session_id --,   wait_duration_ms 
        from dbo.DB_MON_LARGE_WAIT with (nolock) where reg_date = @reg_date
			and wait_duration_ms > @term  and query_text not like 'BACKUP%'
			and program_name not like 'SQLAgent%'
		group by session_id
        
        set @rowcount = @@Rowcount
        set @i = 1
        
        set @msg = '[' + @@servername + '] Large Wait Cnt =' + convert(nvarchar(2), @rowcount) 
        +  ',spid = '
        
        while (@i <= @rowcount)
        begin
        
        	if len(@msg) < 80
        	begin
        		select @session_id  = session_id from @large_wait where seqno = @i
        		
        		if @i = 1
        		begin
        			set @msg = @msg +  convert(nvarchar(4), @session_id) 
        		end
        		else
        		begin
        			set @msg = @msg + ',' +  convert(nvarchar(4), @session_id)
        		end
        		
        	end
        	
        	set @i = @i + 1
        end
  
        if @rowcount >= 1
        begin
        	declare @sms varchar(200)
	
        	if @site = 'G'
        	begin
				set @sms = 'sqlcmd -S GCONTENTSDB,3950 -E -Q"exec sms_admin.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'
			end
		    else if @site = 'I'
			begin
				set @sms = 'sqlcmd -S epdb2 -E -Q"exec smsdb.dbo.up_dba_send_short_msg ''DBA'',''' + @msg + '''"'
			end
			exec xp_cmdshell  @sms
        end
            
end


RETURN

GO
