use master
go

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_top_cpu 
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 2초간 CPU 높은 쿼리
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.sp_mon_top_cpu
     @row_count  int = 15
    ,@delay_time datetime  = '00:00:02'

AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SET LOCK_TIMEOUT 10000

/* USER DECLARE */

/* BODY */
        -- insert sys.dm_exec_requests into temp table !
		select 
    		 session_id
    		,request_id 
    		,connection_id
    		,sql_handle
    		,cpu_time
    		,(writes + reads) as physical_io 
    	into #tmp_requests 
		from sys.dm_exec_requests with(nolock) 
		
	
	  -- delay with parameter

		WAITFOR DELAY @delay_time
		
		
		----------------------------------------------------------------
	  -- find 
	  ----------------------------------------------------------------
	    select top(@row_count) 
    			req.session_id as sid
                ,case when qt.objectid is null then
    			    isnull(substring(qt.text,req.statement_start_offset / 2 + 1,                          
					    (case when req.statement_end_offset = -1                               
				         then len(convert(nvarchar(max), qt.text)) * 2   
                         else req.statement_end_offset end - req.statement_start_offset) / 2), '')
                    else object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)  end [object_name]
    			,(req.cpu_time - tmp.cpu_time) as cpu_gap
    			, req.cpu_time
    			, req.status
    			, req.last_wait_type
    			,(req.reads + req.writes) as physical_io
    			,req.logical_reads
    			,session.login_name 
    			,session.host_name
    			,req.start_time
    			,case when session.program_name like 'SQLAgent - TSQL JobStep%' then j.name else session.program_name end program_name 
    		    --,req.sql_handle
    		    ,substring(qt.text,req.statement_start_offset/2,
				(case when req.statement_end_offset = -1
				then len(convert(nvarchar(max), qt.text)) * 2
				else req.statement_end_offset end - req.statement_start_offset)/2)
				as query_text
    		    ,req.plan_handle
				,req.statement_start_offset
				,req.statement_end_offset
		from sys.dm_exec_requests req with(nolock)
			inner join sys.dm_exec_sessions session with(nolock) on req.session_id = session.session_id
			inner join #tmp_requests tmp with(nolock) 
			    on ( req.session_id = tmp.session_id and  req.request_id = tmp.request_id)
			left outer join msdb.dbo.sysjobs j
	            on substring(session.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
										substring(left(j.job_id,8),5,2) +
										substring(left(j.job_id,8),3,2) +
										substring(left(j.job_id,8),1,2))
			cross apply sys.dm_exec_sql_text(req.sql_handle) as qt
			
		where session.is_user_process = 1 
		    and session.host_name <> @@servername and object_name(qt.objectid,qt.dbid)  != 'sp_mon_top_cpu'
		order by (req.cpu_time - tmp.cpu_time) desc , req.cpu_time desc 


DROP TABLE  #tmp_requests 
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
