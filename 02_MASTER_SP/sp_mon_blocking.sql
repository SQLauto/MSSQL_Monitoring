/*************************************************************************  
* 프로시저명  : dbo.sp_mon_blocking 
* 작성정보    : 2010-02-22 by 윤태진
* 관련페이지  :  
* 내용        :
* 수정정보    : 2010-02-22 by 최보라 수정
**************************************************************************/
CREATE PROCEDURE dbo.sp_mon_blocking
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

/* USER DECLARE */

/* BODY */
select req.session_id as session_id
    ,req.blocking_session_id as blocking_session_id 
    into #temp_blocking
from sys.dm_exec_requests req with(nolock)
where req.session_id > 50

IF exists(select top 1  * from #temp_blocking with(nolock) where blocking_session_id > 0 )
BEGIN
    select
         blocking.sid 
        ,blocking.blocked
        ,blocking.is_blocker
        ,blocking.cpu
        ,blocking.db_name
        ,blocking.object_name
        ,blocking.login_name
        ,blocking.host_name
        ,blocking.program_name
        ,blocking.query_text
        ,blocking.last_wait_type
        ,blocking.total_elapsed_time 
        ,blocking.status
        ,blocking.reads
        ,blocking.writes
        ,blocking.logical_reads
        ,blocking.scheduler_id
        ,blocking.wait_type
        ,blocking.wait_resource
        ,blocking.open_transaction_count

    from (
            select r.session_id  as sid 
            , r.blocking_session_id as blocked
            , 1 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            ,s.login_name
            ,s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2 + 1,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
            as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct blocking_session_id from #temp_blocking with(nolock) )
            
            union all 
            
            select r.session_id  as sid
            , r.blocking_session_id as blocked
            , 0 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            , s.login_name
            , s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
                as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct session_id from #temp_blocking with(nolock) where blocking_session_id > 0 )
    )blocking
    

END

RETURN


