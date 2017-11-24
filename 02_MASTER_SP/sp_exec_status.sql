
CREATE PROC dbo.sp_exec_status
	@sp_name varchar(150)  
AS  
 SET NOCOUNT ON  
 SET QUERY_GOVERNOR_COST_LIMIT 0  
 SELECT @sp_name
 SELECT 
	plan_generation_num, 
	creation_time,  
	last_execution_time,
	execution_count,
	total_worker_time,
	last_worker_time,
	min_worker_time,
	max_worker_time,
	total_worker_time / execution_count as avg_worker_time,
	total_logical_writes,
	last_logical_writes,
	min_logical_writes,
	max_logical_writes,
	total_logical_reads,
	last_logical_reads,
	min_logical_reads,
	max_logical_reads,
	total_logical_reads / execution_count as avg_logical_reads,
	total_elapsed_time,
	last_elapsed_time,
	min_elapsed_time,
	max_elapsed_time,
	substring(qt.text,r.statement_start_offset/2, 
		(case when r.statement_end_offset = -1 
		then len(convert(nvarchar(max), qt.text)) * 2 
		else r.statement_end_offset end - r.statement_start_offset)/2) 
	as query_text   --- this is the statement executing right now
FROM SYS.DM_EXEC_QUERY_STATS r CROSS APPLY SYS.DM_EXEC_SQL_TEXT (PLAN_HANDLE) QT WHERE OBJECTID = OBJECT_ID(@sp_name)  
/*
declare @exe_cnt numeric(30, 5)
declare @total_worker_time numeric(30, 5)
	,@total_logical_writes numeric(30, 5)
	,@total_logical_reads numeric(30, 5)
	,@total_elapsed_time numeric(30, 5)
 SELECT 
	@exe_cnt = sum(execution_count),
	@total_worker_time = sum(total_worker_time),
	@total_logical_writes = sum(total_logical_writes),
	@total_logical_reads = sum(total_logical_reads),
	@total_elapsed_time = sum(total_elapsed_time)
FROM SYS.DM_EXEC_QUERY_STATS r CROSS APPLY SYS.DM_EXEC_SQL_TEXT (PLAN_HANDLE) QT WHERE OBJECTID = OBJECT_ID(@sp_name)  


select	@exe_cnt / sum(execution_count) as execution,
	@total_worker_time / sum(total_worker_time) as total_worker_time, 
	@total_logical_reads / sum(total_logical_reads) as total_logical_reads, 
	@total_logical_writes / sum(total_logical_writes) as total_logical_writes, 
	@total_elapsed_time / sum(total_elapsed_time) as total_elapsed_time 
from sys.dm_exec_query_stats
*/
SET NOCOUNT OFF  


