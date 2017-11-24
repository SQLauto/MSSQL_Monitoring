/*----------------------------------------------------
    Date    : 2007-11-05
    Note    : 캐쉬의 실행 상황 보기 쿼리
    No.     :
*----------------------------------------------------*/
 
 
SELECT TOP 300 est.objectid, object_name(est.objectid) AS objname, ecp.usecounts, 
		eqs.execution_count, eqs.plan_generation_num, eqs.total_elapsed_time, 
		(eqs.total_elapsed_time/ eqs.execution_count) AS avg_elapsed_time,
		eqs.total_worker_time, (eqs.total_worker_time/execution_count) AS avg_worker_time,
		eqs.total_logical_reads, eqs.total_logical_writes,total_physical_reads,
		(eqs.total_logical_reads /eqs.execution_count) AS avg_logical_reads, 
		(eqs.total_logical_writes/eqs.execution_count) AS avg_logical_writes,
		(total_physical_reads /eqs.execution_count) AS avg_physical_reads,
		ecp.cacheobjtype, ecp.objtype, ecp.bucketid, est.dbid, epa.value AS setopts, 
		ecp.plan_handle, eqs.sql_handle
FROM sys.dm_exec_cached_plans AS ecp
	INNER JOIN (SELECT plan_handle, sql_handle, sum(plan_generation_num) AS plan_generation_num,
						SUM(execution_count) AS execution_count, SUM(total_worker_time/1000.00) AS total_worker_time,
						SUM(total_elapsed_time /1000.00) AS total_elapsed_time,
						SUM(total_logical_reads) AS total_logical_reads, SUM(total_physical_reads) AS total_physical_reads,
						SUM(total_logical_writes) AS total_logical_writes
				 FROM sys.dm_exec_query_stats
			     GROUP BY plan_handle, sql_handle) AS eqs ON ecp.plan_handle = eqs.plan_handle
	OUTER APPLY sys.dm_exec_sql_text(ecp.plan_handle) AS est
	CROSS APPLY sys.dm_exec_plan_attributes(ecp.plan_handle) AS epa
WHERE est.dbid = DB_ID('TIGER') AND epa.attribute = 'set_options'
ORDER BY usecounts desc 


-- PIVOT 사용
SELECT ecp.*, est.objectid , object_name(est.objectid)
FROM
	(SELECT TOP 300 bucketid, pvt.objectid, usecounts, cacheobjtype, objtype,
			 pvt.dbid, pvt.set_options, pvt.sql_handle, plan_handle 
	FROM (
		SELECT bucketid, epa.attribute, epa.value , usecounts, cacheobjtype, objtype, plan_handle  
		FROM sys.dm_exec_cached_plans 
			CROSS APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
		  ) AS ecpa
	PIVOT (MAX(ecpa.value) FOR ecpa.attribute IN ("set_options", "sql_handle", "dbid", "objectid")) AS pvt
	WHERE pvt.dbid = 12
	ORDER BY usecounts desc )  AS ecp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS est