exec sp_readerrorlog 0

--====================================
--시스템 모니터링
--======================================
--1. CPU변화량 확인
sp_who4

EXEC tiger.dbo.up_DBA_who3_tiger

--2. blocked
EXEC dba.dbo.up_DBA_CheckProcessStatus2

--3. sqlperf(threads)
exec dba.dbo.up_DBA_CheckThreads 'io'
exec dba.dbo.up_DBA_CheckThreads 'cpu'
exec dba.dbo.up_DBA_CheckThreads 'mem'


--4. tempdb 오래 사용하는 내용
select name,log_reuse_wait, log_reuse_wait_desc from sys.databases

--5.blocking정보
exec tiger.dbo.up_DBA_show_blockinfo


--- 6.모니터링 상태 보는것 
SELECT top 50 
		req.session_id, req.blocking_session_id as blocking,req.cpu_time,req.last_wait_type,
		datediff(mi, ses.login_time, getdate()) AS  '분',  req.status,
		db_name(req.database_id) as database_name,req.command, 
	    (CASE WHEN  LEFT(ses.program_name, 8) = 'SQLAgent' 
			  THEN (SELECT job_name FROM DBA.DBO.JOBS WITH (NOLOCK) WHERE job_id_char =  substring(ses.program_name, 32,32) AND enabled = 1)
		 END) AS job_name,
		object_name(sql_text.objectid) AS 'sp_ame',
		(CASE WHEN (sql_text.objectid) IS NULL THEN sql_text.text  ELSE NULL END) AS 'query',
		req.reads, req.logical_reads, req.writes,
		req.percent_complete, req.row_count,
		 ses.login_name, ses.host_name, ses.program_name
FROM sys.dm_exec_requests AS req with (nolock)
		INNER JOIN sys.dm_exec_sessions AS ses with (nolock) ON req.session_id = ses.session_id
		CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS sql_text
WHERE req.session_id > 50  and last_wait_type <> 'WAITFOR' --and req.wait_time > 0 
ORDER BY req.cpu_time desc

-- ========================
--   2000용
-- ========================
--select top 50  lastwaittype, open_tran, cmd, convert(varchar(25),hostname),  'DBCC INPUTBUFFER(' + CAST(SPID AS VARCHAR(5)) + ')', 'KILL ' + CAST(SPID AS VARCHAR(5)), waitresource, * 
--from master..sysprocesses 
--where spid > 50 and waittype > 0 and waittime > 0 and lastwaittype <> 'WAITFOR'
--order by cpu desc

-- 7. 대쉬보드에서 보는 쿼리
--타입 그룹별
SELECT 
  msdb.MS_PerfDashboard.fn_WaitTypeCategory(r.wait_type) AS wait_category, 
  count(r.session_id)
  --count(r.session_id)
 FROM sys.dm_exec_requests AS r  with(nolock)
 INNER JOIN sys.dm_exec_sessions AS s with(nolock) ON r.session_id = s.session_id
 WHERE r.wait_type IS NOT NULL  
  AND s.is_user_process = 0x1
group by msdb.MS_PerfDashboard.fn_WaitTypeCategory(r.wait_type)
order by wait_category desc

--상세 
SELECT 
  r.session_id, 
  msdb.MS_PerfDashboard.fn_WaitTypeCategory(r.wait_type) AS wait_category, 
  r.wait_type, 
  r.wait_time
 FROM sys.dm_exec_requests AS r 
  INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
 WHERE r.wait_type IS NOT NULL  
  AND s.is_user_process = 0x1
order by wait_category desc



-- 3. 블로킹
select * into #temp_blocking from sys.dm_exec_requests 
cross apply sys.dm_exec_sql_text(sql_handle)
--cross apply sys.dm_exec_query_plan(plan_handle)
where session_id > 50
and blocking_session_id > 0
order by cpu_time desc

--order by total_elapsed_time desc
select object_name([objectid]),*
from sys.dm_exec_requests
cross apply sys.dm_exec_sql_text(sql_handle)
where session_id in (select blocking_session_id from #temp_blocking)

select object_name([objectid]),*
from sys.dm_exec_requests
cross apply sys.dm_exec_sql_text(sql_handle)
where session_id in (select  session_id from #temp_blocking)
drop table #temp_blocking


-- 텍스트까지 다 보임
SELECT 
       ca.text as SQL_TEXT
,      ses.host_name as HOST
--     ,   cast(datediff(mi, ses.login_time, getdate()) as varchar) + '분' AS '실행시간'\
,      (req.total_elapsed_time /100000)
,      ses.program_name as program_name
,		ses.login_name
,      DB_NAME(req.database_id) as user_db_name
,		ses.client_version
,      con.client_net_address
,      req.*
FROM sys.dm_exec_requests as req with (nolock)
inner join sys.dm_exec_sessions as ses with (nolock) on req.session_id = ses.session_id
inner join sys.dm_exec_connections as con with (nolock) on ses.session_id = con.session_id
cross apply sys.dm_exec_sql_text (req.sql_handle) as ca
where req.session_id > 50
and req.last_wait_type not like 'WAITFOR%'

