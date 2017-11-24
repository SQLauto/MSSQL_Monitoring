--====================================
--NUMA 모드 스캐줄러 모니터링 상태
--====================================

SELECT session_id,
    CONVERT (varchar(10), t1.status) AS status,
    CONVERT (varchar(20), t1.command) AS command,
    CONVERT (varchar(15), t2.state) AS worker_state
FROM sys.dm_exec_requests AS t1 JOIN sys.dm_os_workers AS t2
ON  t2.task_address = t1.task_address
WHERE command = 'RESOURCE MONITOR'