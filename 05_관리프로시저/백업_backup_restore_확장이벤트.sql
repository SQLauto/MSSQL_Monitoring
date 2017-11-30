-- backup, restore monitoring
use master;

CREATE EVENT SESSION [Backup progress] ON SERVER
ADD EVENT sqlserver.backup_restore_progress_trace
(
    ACTION(package0.event_sequence, sqlserver.session_id)
    -- to only capture restore operations:
    WHERE [operation_type] = 1
	-- to only capture backup operations:
    --WHERE [operation_type] = 0
)
/*
,ADD EVENT sqlserver.databases_backup_restore_throughput(
    ACTION(sqlserver.client_hostname,sqlserver.database_name))
-- add session_id
,ADD EVENT sqlos.task_completed(
    ACTION(package0.event_sequence,sqlserver.session_id))
,ADD EVENT sqlos.task_started(
    ACTION(package0.event_sequence,sqlserver.session_id))
,ADD EVENT sqlserver.file_write_completed(
		SET collect_path=(1)
		ACTION(package0.event_sequence,sqlos.task_address,sqlserver.session_id))
*/
ADD TARGET package0.event_file
(
  SET filename = N'D:\backup_extended_event\backup_extended_event.xel'
      , max_file_size =(100)
      , max_rollover_files = (20)
) -- default options are probably ok
WITH (STARTUP_STATE=OFF
	,MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS
 );

ALTER EVENT SESSION [Backup progress] ON SERVER STATE = START;





/****** 테스트 해 본 쿼리 ********/

-- 방법 1
CREATE EVENT SESSION [Backup trace] ON SERVER
ADD EVENT sqlserver.backup_restore_progress_trace
ADD TARGET package0.event_file(SET filename=N'Backup trace')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

CREATE EVENT SESSION [test] ON SERVER
ADD EVENT sqlserver.backup_restore_progress_trace
   (WHERE [operation_type] = 1 )   -- Filter for restore operation
ADD TARGET package0.event_file(SET filename=N'test')
WITH (STARTUP_STATE=OFF)
GO


CREATE EVENT SESSION [Backup_Restore_Trace] ON SERVER
ADD EVENT sqlos.async_io_completed(
    ACTION(package0.event_sequence,sqlos.task_address,sqlserver.session_id)),
ADD EVENT sqlos.async_io_requested(
    ACTION(package0.event_sequence,sqlos.task_address,sqlserver.session_id)),
ADD EVENT sqlos.task_completed(
    ACTION(package0.event_sequence,sqlserver.session_id)),
ADD EVENT sqlos.task_started(
    ACTION(package0.event_sequence,sqlserver.session_id)),
ADD EVENT sqlserver.backup_restore_progress_trace(
    ACTION(package0.event_sequence,sqlos.task_address,sqlserver.session_id)),
ADD EVENT sqlserver.file_write_completed(SET collect_path=(1)
    ACTION(package0.event_sequence,sqlos.task_address,sqlserver.session_id))
ADD TARGET package0.event_file(SET filename=N'Backup_Restore_Trace')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)


-- 방법 2
CREATE EVENT SESSION [Backup progress] ON SERVER
ADD EVENT sqlserver.backup_restore_progress_trace
(
    ACTION(package0.event_sequence)

    -- to only capture backup operations:
    --WHERE [operation_type] = 0

    -- to only capture restore operations:
    --WHERE [operation_type] = 1
)
ADD EVENT sqlserver.databases_backup_restore_throughput(
    ACTION(sqlserver.client_hostname,sqlserver.database_name))
ADD TARGET package0.event_file
(
  SET filename = N'E:\SQL2016\backup_extended_event\backup_extended_event.xel'
) -- default options are probably ok
WITH (STARTUP_STATE=OFF);
GO

ALTER EVENT SESSION [Backup progress] ON SERVER STATE = START;
GO




USE [master];
GO
CREATE DATABASE floob;
GO
(SELECT s1.* INTO floob.dbo.what
  FROM sys.all_objects AS s1
  CROSS JOIN sys.all_objects;
GO
BACKUP DATABASE floob TO DISK = 'c:\temp\floob.bak'
  WITH INIT, COMPRESSION, STATS = 30;
GO
DROP DATABASE floob;
GO)
RESTORE DATABASE floob FROM DISK = 'c:\temp\floob.bak'
  WITH REPLACE, RECOVERY;

;WITH x AS
(
  SELECT ts,op,db,msg,es
  FROM
  (
   SELECT
    ts  = x.value(N'(event/@timestamp)[1]', N'datetime2'),
    op  = x.value(N'(event/data[@name="operation_type"]/text)[1]', N'nvarchar(32)'),
    db  = x.value(N'(event/data[@name="database_name"])[1]', N'nvarchar(128)'),
    msg = x.value(N'(event/data[@name="trace_message"])[1]', N'nvarchar(max)'),
    es  = x.value(N'(event/action[@name="event_sequence"])[1]', N'int')
   FROM
   (
    SELECT x = CONVERT(XML, event_data)
     FROM sys.fn_xe_file_target_read_file
          (N'c:\temp\Backup--Progress*.xel', NULL, NULL, NULL)
   ) AS y
  ) AS x
  WHERE op = N'Backup' -- N'Restore'
  AND db = N'floob'
  AND ts > CONVERT(DATE, SYSUTCDATETIME())
)
SELECT /* x.db, x.op, x.ts, */
  [Message] = x.msg,
  Duration = COALESCE(DATEDIFF(MILLISECOND, x.ts,
             LEAD(x.ts, 1) OVER(ORDER BY es)),0)
FROM x
ORDER BY es;

ALTER EVENT SESSION [Backup progress] ON SERVER STATE = STOP;

