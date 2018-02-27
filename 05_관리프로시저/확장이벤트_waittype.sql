

--DROP EVENT SESSION [TrackResourceWaits] ON SERVER
--GO



CREATE EVENT SESSION [TrackResourceWaits] ON SERVER
ADD EVENT sqlos.wait_info(
    ACTION(package0.event_sequence
        ,package0.last_error
        ,sqlos.scheduler_id
        ,sqlserver.client_hostname
        ,sqlserver.client_pid
        ,sqlserver.database_id
        ,sqlserver.database_name
        ,sqlserver.is_system
        ,sqlserver.nt_username
        ,sqlserver.plan_handle
        ,sqlserver.session_id
        ,sqlserver.session_nt_username
    ,sqlserver.sql_text,sqlserver.transaction_id)
 WHERE
        (opcode = 1 --End Events Only
            AND duration > 100 -- had to accumulate 100ms of time, 얼마 이상 할지 결정 하세요.
            AND ((wait_type > 0 AND wait_type < 22) -- LCK_ waits
                    OR (wait_type > 31 AND wait_type < 38) -- LATCH_ waits
                    OR (wait_type > 47 AND wait_type < 54) -- PAGELATCH_ waits
                    OR (wait_type > 63 AND wait_type < 70) -- PAGEIOLATCH_ waits
                    OR (wait_type > 96 AND wait_type < 100) -- IO (Disk/Network) waits
                    OR (wait_type = 107) -- RESOURCE_SEMAPHORE waits
                    OR (wait_type = 113) -- SOS_WORKER waits
                    OR (wait_type = 120) -- SOS_SCHEDULER_YIELD waits
                    OR (wait_type = 178) -- WRITELOG waits
                    OR (wait_type > 174 AND wait_type < 177) -- FCB_REPLICA_ waits
                    OR (wait_type = 186) -- CMEMTHREAD waits
                    OR (wait_type = 187) -- CXPACKET waits
                    OR (wait_type = 207) -- TRACEWRITE waits
                    OR (wait_type = 269) -- RESOURCE_SEMAPHORE_MUTEX waits
                    OR (wait_type = 283) -- RESOURCE_SEMAPHORE_QUERY_COMPILE waits
                    OR (wait_type = 284) -- RESOURCE_SEMAPHORE_SMALL_QUERY waits
                )
        )
)
ADD TARGET package0.event_file
(SET filename=N'H:\extened_event\extended_event_waitetype.xel' --  디렉 토리 폴더 결정 하세요.
,max_file_size=(102400))
/*메모리에서 저장 하고 보고 싶을때
ADD TARGET package0.ring_buffer(SET max_memory=4096)
WITH (EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY=5 SECONDS)
*/
WITH (STARTUP_STATE=OFF, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=5 SECONDS)
GO

ALTER EVENT SESSION [TrackResourceWaits] ON SERVER STATE = START;

-- 쿼리 조회
-- 이거 양 많으면 오래 걸리고 결과 안 나옵니다. 그러니 대기 시간 숫자, wait_type 을 줄이는게 중요 합니다.
with xevent as
(
select top 10
 xevent.value('(event/@name)[1]', 'varchar(50)') AS event_name,
 DATEADD(hh,DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), xevent.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
   COALESCE(xevent.value('(event/data[@name="database_id"]/value)[1]', 'int'),
      xevent.value('(event/action[@name="database_id"]/value)[1]', 'int')) AS database_id,
    xevent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id],
    xevent.value('(event/action[@name="session_nt_username"]/value)[1]', 'sysname') AS session_nt_username,
    xevent.value('(event/action[@name="nt_username"]/value)[1]', 'sysname') AS nt_username,
    xevent.value('(event/data[@name="wait_type"]/text)[1]', 'nvarchar(4000)') AS [wait_type],
    xevent.value('(event/data[@name="opcode"]/text)[1]', 'nvarchar(4000)') AS [opcode],
    xevent.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration],
    xevent.value('(event/data[@name="max_duration"]/value)[1]', 'bigint') AS [max_duration],
    xevent.value('(event/data[@name="total_duration"]/value)[1]', 'bigint') AS [total_duration],
    xevent.value('(event/data[@name="signal_duration"]/value)[1]', 'bigint') AS [signal_duration],
    xevent.value('(event/data[@name="completed_count"]/value)[1]', 'bigint') AS [completed_count],
    xevent.value('(event/action[@name="plan_handle"]/value)[1]', 'nvarchar(4000)') AS [plan_handle],
    xevent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(4000)') AS [sql_text]
FROM
(
SELECT top 20 xevent = CONVERT(XML, event_data)
    FROM sys.fn_xe_file_target_read_file('H:\extened_event\extended_event_waitetype_*.xel', NULL, NULL, NULL)

) AS y
)
select  *
from xevent
where [duration] > 10


-- 혹은 메모리에 직업 할 경우 그런데 한참 지난 다음에 보려면 파일로 저장 해야 한다.
SELECT
    event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    DATEADD(hh,
        DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP),
        event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
    COALESCE(event_data.value('(event/data[@name="database_id"]/value)[1]', 'int'),
        event_data.value('(event/action[@name="database_id"]/value)[1]', 'int')) AS database_id,
    event_data.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id],
    event_data.value('(event/data[@name="wait_type"]/text)[1]', 'nvarchar(4000)') AS [wait_type],
    event_data.value('(event/data[@name="opcode"]/text)[1]', 'nvarchar(4000)') AS [opcode],
    event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration],
    event_data.value('(event/data[@name="max_duration"]/value)[1]', 'bigint') AS [max_duration],
    event_data.value('(event/data[@name="total_duration"]/value)[1]', 'bigint') AS [total_duration],
    event_data.value('(event/data[@name="signal_duration"]/value)[1]', 'bigint') AS [signal_duration],
    event_data.value('(event/data[@name="completed_count"]/value)[1]', 'bigint') AS [completed_count],
    event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'nvarchar(4000)') AS [plan_handle],
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(4000)') AS [sql_text]
FROM
(    SELECT XEvent.query('.') AS event_data
    FROM
    (    -- Cast the target_data to XML
        SELECT CAST(target_data AS XML) AS TargetData
        FROM sys.dm_xe_session_targets st
        JOIN sys.dm_xe_sessions s
            ON s.address = st.event_session_address
        WHERE name = 'TrackResourceWaits'
          AND target_name = 'ring_buffer'
    ) AS Data
    -- Split out the Event Nodes
    CROSS APPLY TargetData.nodes ('RingBufferTarget/event') AS XEventData (XEvent)
) AS tab (event_data)
