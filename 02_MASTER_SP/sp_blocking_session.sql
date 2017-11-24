CREATE PROC SP_BLOCKING_SESSIONS
AS 

SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ COMMITTED  

select 		r.session_id
		,status
		,isnull(db_name(qt.dbid), qt.dbid) as db_nm
		,isnull(object_name(qt.objectid), qt.objectid) as object_nm
		,r.cpu_time
		,r.total_elapsed_time
		,r.logical_reads
		,r.writes
		,r.reads
		,r.last_wait_type
		,r.wait_time
		,r.blocking_session_id as blocking
		,substring(qt.text,r.statement_start_offset/2, 
			(case when r.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else r.statement_end_offset end - r.statement_start_offset)/2) 
		as query_text   --- this is the statement executing right now
		--,r.scheduler_id
from sys.dm_exec_requests r
cross apply sys.dm_exec_sql_text(sql_handle) as qt
inner join (select blocking_session_id from sys.dm_exec_requests where blocking_session_id > 0) r2 on r.session_id = r2.blocking_session_id
where r.session_id > 50
order by r.session_id

SET NOCOUNT OFF
