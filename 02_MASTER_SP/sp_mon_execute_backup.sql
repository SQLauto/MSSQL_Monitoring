use master
go
/*************************************************************************
* 프로시저명  : dbo.sp_mon_execute_backup
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :
* 내용        : sysprocess조회
* 수정정보    : 2013-10-18 BY 최보라, 조건 정리,
              2017-11-29 by 최보라, 확장 이벤트 쿼리 추가
*************************************************************************/
ALTER PROCEDURE [dbo].[sp_mon_execute_backup]
  @reg_dt   date = null,
  @db_name  sysname = null

AS

SET NOCOUNT ON
SET @reg_dt = case when @reg_dt is null then convert(date, getdate()) else @reg_dt end

  -- backupIO 예상 완료 시간
    select    convert(time(0), getdate()) as run_time,
                r.session_id as [sid]
        ,CONVERT(NUMERIC(6, 2), [r].[percent_complete]) AS [PERCENT Complete]
        ,[r].[command]
        ,CONVERT(VARCHAR(20), DATEADD(ms, [r].[estimated_completion_time]
        ,GETDATE()), 20) AS [ETA COMPLETION TIME]
        --,CONVERT(NUMERIC(6, 2), [r].[total_elapsed_time] / 1000.0 / 60.0) AS [Total EXEC MIN]
        ,CONVERT(NUMERIC(6, 2), [r].[estimated_completion_time] / 1000.0 / 60.0) AS [ETA MIN]
        ,CONVERT(NUMERIC(6, 2), [r].[estimated_completion_time] / 1000.0 / 60.0/ 60.0) AS [ETA Hours]
          ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(j.name, '')
             else s.program_name end program_name
          ,r.blocking_session_id [blocked]
          ,r.status
          ,r.cpu_time [cpu]
          ,datediff(ss, r.start_time, getdate()) as [duration]
          --,db_name(qt.dbid) db_name
          ,r.wait_type
        ,r.logical_reads
        ,convert(money,round(r.logical_reads/128.0,2))as logical_MB
        --  ,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
        --    ,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,
        --(case when r.statement_end_offset = -1
        --    then len(convert(nvarchar(max), qt.text)) * 2
        --else r.statement_end_offset end - r.statement_start_offset) / 2), '')
        --    as query_text
          ,r.last_wait_type
        ,s.login_name
          ,s.host_name
          --,qt.dbid
          --,qt.objectid
                ,r.total_elapsed_time
          ,r.reads
          ,r.writes
          ,r.scheduler_id
          ,CASE s.transaction_isolation_level
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
          ,r.wait_resource
          ,r.open_transaction_count
          ,r.row_count
        ,r.percent_complete as '%'
          ,r.plan_handle
        from sys.dm_exec_requests r
            inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                --cross apply sys.dm_exec_sql_text(sql_handle) as qt
            left outer join msdb.dbo.sysjobs j
              on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
                            substring(left(j.job_id,8),5,2) +
                            substring(left(j.job_id,8),3,2) +
                            substring(left(j.job_id,8),1,2))
    --    where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
        --or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR')
        --or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
             where  r.session_id != @@spid
        -- and  [r].[estimated_completion_time] > 0
       and   r.command in ('BACKUP DATABASE','RESTORE DATABASE');

-- extended event query
;WITH xevent AS
(
  SELECT timestamp,operation_type,database_name,trace_message,event_sequence, session_id
  FROM
  (
   SELECT
    timestamp  = xevent.value(N'(event/@timestamp)[1]', N'datetime'),
    operation_type  = xevent.value(N'(event/data[@name="operation_type"]/text)[1]', N'nvarchar(32)'),
    database_name  = xevent.value(N'(event/data[@name="database_name"])[1]', N'nvarchar(128)'),
    trace_message = xevent.value(N'(event/data[@name="trace_message"])[1]', N'nvarchar(max)'),
    event_sequence  = xevent.value(N'(event/action[@name="event_sequence"])[1]', N'int')
  ,session_id =xevent.value(N'(event/action[@name="session_id"])[1]', N'int')
   FROM
   (
    SELECT xevent = CONVERT(XML, event_data)
     FROM sys.fn_xe_file_target_read_file
        (N'D:\backup_extended_event\backup_extended_event_*.xel', NULL, NULL, NULL)
          --(N'E:\SQL2016\backup_extended_event\backup_extended_event_*.xel', NULL, NULL, NULL)
   ) AS y
  ) AS xevent
  where trace_message is not null  and database_name  = case when @db_name is null then database_name else @db_name end
)
SELECT
  [timestamp] = dateadd(hh, 9,xevent.timestamp),
  [event_sequence] = xevent.event_sequence,
  [operation_type] = xevent.operation_type,
  session_id = xevent.session_id,
  db_name = xevent.database_name,
  [message] = replace(xevent.trace_message,char(10), '') ,
  [duration(ms)] = COALESCE(DATEDIFF(millisecond, xevent.timestamp,
             LEAD(xevent.timestamp, 1) OVER(ORDER BY timestamp,  event_sequence)),0)
FROM xevent
WHERE [timestamp] >= @reg_dt
ORDER BY [timestamp], event_sequence;
