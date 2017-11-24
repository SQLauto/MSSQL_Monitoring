USE DBMON
GO



DECLARE @session_id INT = 6066


DECLARE @StartTime DATETIME =  '2017-01-12 17:26:21.223'
DECLARE @EndTime DATETIME = '2017-01-12 17:26:52.833'

SELECT	
		a.runtime,
		a.session_id, 
		a.wait_type,
		ISNULL(a.request_cpu_time,0) as request_cpu_time, 
		ISNULL(a.request_logical_reads,0) * 8 / 1024 as request_logical_reads_MB ,
		ISNULL(a.request_reads,0) as request_reads,
		ISNULL(a.request_writes,0) as request_writes,
		a.request_start_time,
		a.plan_handle,
		a.statement_start_offset,
		a.statement_end_offset,
		a.request_total_elapsed_time,
		--a.last_request_start_time,
		--a.last_request_end_time,
		a.program_name
FROM DB_MON_MS_DAC_REQUEST (nolock) a
WHERE a.runtime BETWEEN @StartTime AND @EndTime
AND a.session_id = @session_id
ORDER BY a.runtime
go

select reg_date,object_name,  cnt_total,cpu_cnt,reads_cnt from [dbo].[DB_MON_QUERY_STATS_V3] (nolock) 
where reg_date > '2017-01-11'
and plan_handle = 0x05000C00C8BB276F40019DF8290000000000000000000000
and statement_start = 22982 and statement_end = 23666
order by reg_date 
