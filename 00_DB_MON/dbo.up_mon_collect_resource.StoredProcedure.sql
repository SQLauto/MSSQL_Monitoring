USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_resource]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_resource
* 작성정보    : 2010-
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_resource] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
insert into db_mon_resource
(
reg_date
,session_id
,request_id
,host_process_id
,status
,host_name
,program_name
,cpu_time
,db_name
,schema_name
,object_name
,query_text
,time_sec
,dop
,grant_time
,requested_memory_kb
,req_granted_memory_kb
,granted_memory_kb
,used_memory_kb
,max_used_memory_kb
,query_cost
,group_id
,pool_id)
select getdate() as reg_date,req.session_id , req.request_id, ses.host_process_id
	,req.status, ses.host_name, ses.program_name, req.cpu_time, db_name(qt.dbid) as db_name	
	,object_schema_name(qt.objectid, qt.dbid) as schema_name
    ,object_name(qt.objectid, qt.dbid)  as object_name			  
    ,CASE WHEN   req.statement_end_offset = -1 and ( (req.statement_start_offset )  > DATALENGTH (qt.text) )
    THEN  convert(varchar(4000), 
    			   substring(isnull(qt.text, '') 
    				, 1, ( ( DATALENGTH (qt.text) - 1 )/2 ) + 1 ) )
    ELSE  convert(varchar(4000), substring(isnull(qt.text, '') 
    		, (req.statement_start_offset / 2) + 1
    		, (( case when req.statement_end_offset = -1 then DATALENGTH (qt.text) else req.statement_end_offset end	
    				- req.statement_start_offset ) /2 ) + 1) )
    END  as query_text
	,mem.timeout_sec
	,mem.dop, mem.grant_time, mem.requested_memory_kb, (req.granted_query_memory *8 ) as req_granted_query_memory
	,mem.granted_memory_kb, mem.used_memory_kb, mem.max_used_memory_kb
    ,mem.query_cost, mem.group_id, mem.pool_id
from sys.dm_exec_requests  as req with(nolock)
 inner join sys.dm_exec_sessions as ses with (nolock) on req.session_id = ses.session_id
 left join sys.dm_exec_query_memory_grants as mem with(nolock) on req.request_id = mem.request_id
		and req.session_id = mem.session_id and req.scheduler_id = mem.scheduler_id
 outer apply sys.dm_exec_sql_text(req.sql_handle) as qt 
where req.session_id > 50
order by req.granted_query_memory desc



RETURN


GO
