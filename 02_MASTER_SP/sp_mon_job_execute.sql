
/*************************************************************************  
* 프로시저명  : dbo.sp_mon_job_execute
* 작성정보    : 2013-09-05 by 유진호
* 관련페이지  :  
* 내용        : 수행 JOB 조회
* 수정정보    :
*************************************************************************/
CREATE PROC [dbo].[sp_mon_job_execute]
@ISWAITFOR INT = 0,
@PLAN INT = 0
AS
BEGIN
	SET NOCOUNT ON

	IF @PLAN = 0
	BEGIN
		SELECT           
		x.session_id as session_id,				
		COALESCE(x.blocking_session_id, 0) as blocked,
		CASE LEFT(x.program_name,15)
			WHEN 'SQLAgent - TSQL' THEN 
			(     select top 1 j.name from msdb.dbo.sysjobs (nolock) j
			inner join msdb.dbo.sysjobsteps (nolock) s on j.job_id=s.job_id
			where right(cast(s.job_id as nvarchar(50)),10) =RIGHT(substring(x.program_name,30,34),10) )
			WHEN 'SQL Server Prof' THEN 'SQL Server Profiler'
			ELSE x.program_name
		END as Program_name,
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(x.sql_handle)) as object_name,
		x.Status as status,
		x.TotalCPU as cpu,
		--x.duration as '분',
		CONVERT(nvarchar(30), getdate()-x.Start_time, 108) as Elap_time,
		db_name(x.database_id) as db_name,
		x.wait_type,
		--x.last_wait_type,
		x.logical_reads,				
		--x.totalElapsedTime as total_elapsed_time,
		x.totalReads as reads, -- total reads
		x.totalWrites as writes, --total writes			
		x.Writes_in_tempdb as tempdb,				
		(
			SELECT substring(text,x.statement_start_offset/2,
				(case when x.statement_end_offset = -1
				then len(convert(nvarchar(max), text)) * 2
				else x.statement_end_offset end - x.statement_start_offset+3)/2)
			FROM sys.dm_exec_sql_text(x.sql_handle)
		FOR XML PATH(''), TYPE
		) AS query_text,
		x.tx_level,
		x.wait_resource,
		x.Login_name,
		x.Host_name,
		x.Start_time,	
		x.open_transaction_count,
		x.percent_complete AS '%', 
		(
			SELECT
				p.text
				FROM
				(
					SELECT
						sql_handle,statement_start_offset,statement_end_offset
					FROM sys.dm_exec_requests r2
					WHERE
						r2.session_id = x.blocking_session_id
				) AS r_blocking
				CROSS APPLY
				(
					SELECT substring(text,r_blocking.statement_start_offset/2,
					(case when r_blocking.statement_end_offset = -1
					then len(convert(nvarchar(max), text)) * 2
					else r_blocking.statement_end_offset end - r_blocking.statement_start_offset+3)/2)
					FROM sys.dm_exec_sql_text(r_blocking.sql_handle)
					FOR XML PATH(''), TYPE
				) p (text)
		)  as blocking_text,				
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(
		(select top 1 sql_handle FROM sys.dm_exec_requests r3 WHERE r3.session_id =x.blocking_session_id))) as blocking_obj				
		FROM
		(
		SELECT
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				datediff(mi, r.start_time, getdate()) as [duration],
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END AS tx_level,
				SUM(cast(r.total_elapsed_time as bigint)) /1000 as totalElapsedTime, --CAST AS BIGINT to fix invalid data convertion when high activity
				SUM(cast(r.reads as bigint)) AS totalReads,
				SUM(cast(r.writes as bigint)) AS totalWrites,
				SUM(cast(r.cpu_time as bigint)) AS totalCPU,
				SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
		FROM sys.dm_exec_requests r
		JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
		JOIN sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id =tsu.request_id
		WHERE r.status IN ('running', 'runnable', 'suspended')
		GROUP BY
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END
		) x
		where x.session_id <> @@spid
		AND (program_name like '%SQL Job%'
		OR program_name like '%SQLCMD%')
		AND ((@iswaitfor = 1 and last_wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
		order by x.totalCPU desc
	END
	ELSE IF @PLAN = 1
	BEGIN
		SELECT           
		x.session_id as session_id,				
		COALESCE(x.blocking_session_id, 0) as blocked,
		CASE LEFT(x.program_name,15)
			WHEN 'SQLAgent - TSQL' THEN 
			(     select top 1 j.name from msdb.dbo.sysjobs (nolock) j
			inner join msdb.dbo.sysjobsteps (nolock) s on j.job_id=s.job_id
			where right(cast(s.job_id as nvarchar(50)),10) =RIGHT(substring(x.program_name,30,34),10) )
			WHEN 'SQL Server Prof' THEN 'SQL Server Profiler'
			ELSE x.program_name
		END as Program_name,
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(x.sql_handle)) as object_name,
		x.Status as status,
		x.TotalCPU as cpu,
		--x.duration as '분',
		CONVERT(nvarchar(30), getdate()-x.Start_time, 108) as Elap_time,
		db_name(x.database_id) as db_name,
		x.wait_type,
		--x.last_wait_type,
		x.logical_reads,				
		--x.totalElapsedTime as total_elapsed_time,
		x.totalReads as reads, -- total reads
		x.totalWrites as writes, --total writes			
		x.Writes_in_tempdb as tempdb,				
		(
			SELECT substring(text,x.statement_start_offset/2,
				(case when x.statement_end_offset = -1
				then len(convert(nvarchar(max), text)) * 2
				else x.statement_end_offset end - x.statement_start_offset+3)/2)
			FROM sys.dm_exec_sql_text(x.sql_handle)
		FOR XML PATH(''), TYPE
		) AS query_text,
		x.tx_level,
		x.wait_resource,
		x.Login_name,
		x.Host_name,
		x.Start_time,	
		x.open_transaction_count,
		x.percent_complete AS '%',
		pt.query_plan AS plan_handle,
		(
			SELECT
				p.text
				FROM
				(
					SELECT
						sql_handle,statement_start_offset,statement_end_offset
					FROM sys.dm_exec_requests r2
					WHERE
						r2.session_id = x.blocking_session_id
				) AS r_blocking
				CROSS APPLY
				(
					SELECT substring(text,r_blocking.statement_start_offset/2,
					(case when r_blocking.statement_end_offset = -1
					then len(convert(nvarchar(max), text)) * 2
					else r_blocking.statement_end_offset end - r_blocking.statement_start_offset+3)/2)
					FROM sys.dm_exec_sql_text(r_blocking.sql_handle)
					FOR XML PATH(''), TYPE
				) p (text)
		)  as blocking_text,				
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(
		(select top 1 sql_handle FROM sys.dm_exec_requests r3 WHERE r3.session_id =x.blocking_session_id))) as blocking_obj				
		FROM
		(
		SELECT
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				datediff(mi, r.start_time, getdate()) as [duration],
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END AS tx_level,
				SUM(cast(r.total_elapsed_time as bigint)) /1000 as totalElapsedTime, --CAST AS BIGINT to fix invalid data convertion when high activity
				SUM(cast(r.reads as bigint)) AS totalReads,
				SUM(cast(r.writes as bigint)) AS totalWrites,
				SUM(cast(r.cpu_time as bigint)) AS totalCPU,
				SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
		FROM sys.dm_exec_requests r
		JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
		JOIN sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id =tsu.request_id
		WHERE r.status IN ('running', 'runnable', 'suspended')
		GROUP BY
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END
		) x
		CROSS APPLY sys.dm_exec_query_plan(x.plan_handle) as pt
		where x.session_id <> @@spid
		AND (program_name like '%SQL Job%'
		OR program_name like '%SQLCMD%')
		AND ((@iswaitfor = 1 and last_wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
		order by x.totalCPU desc
	END
END



