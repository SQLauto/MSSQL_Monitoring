
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitoring_sysprocess 
* 작성정보    : 2010-02-26 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    : exec up_dba_monitoring_sysprocess 0, 0
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitoring_sysprocess
    @iswaitfor      tinyint = 0
   ,@plan           tinyint = 0

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @get_date datetime
/* BODY */

--------------------------------------------------
-- 데이터 삭제
-------------------------------------------------
declare @min_value datetime, @max_value datetime, @new_value datetime, @now datetime

select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = 'PF__MONITOR_SYSPROCESS_REG_DT'



if @max_value <= GETDATE()
begin
	
	SET @new_value = DATEADD(day, 1, @max_value)

    ALTER TABLE MONITOR_SYSPROCESS SWITCH PARTITION 1 TO MONITOR_SYSPROCESS_SWITCH
    -- 데이터 삭제
    TRUNCATE TABLE MONITOR_SYSPROCESS_SWITCH
    
    ALTER PARTITION SCHEME PS__MONITOR_SYSPROCESS_REG_DT NEXT USED [PRIMARY]

    ALTER PARTITION FUNCTION PF__MONITOR_SYSPROCESS_REG_DT() MERGE RANGE (@min_value)

    ALTER PARTITION FUNCTION PF__MONITOR_SYSPROCESS_REG_DT() SPLIT RANGE (@new_value)
   
end

set @get_date = getdate()

IF @plan = 0    -- not query plan
BEGIN
    INSERT INTO dbo.MONITOR_SYSPROCESS 
    (reg_dt, sid, blocked, status, cpu, duration, dbname, objectname, query_text, last_wait_type
    ,login_name, host_name, program_name, dbid, objectid, total_elapsed_time, wait_type
    ,reads, writes, logical_reads, scheduler_id, tx_level
    ,wait_resource, open_tran_cnt, row_count, plan_handle)
     select      @get_date as reg_dt
                , r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [objectname]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
                ,r.last_wait_type
                ,s.login_name
    			,s.host_name
                ,s.program_name
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
                ,r.wait_type
    			,r.reads
    			,r.writes
    			,r.logical_reads
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
    			,r.plan_handle
		from sys.dm_exec_requests r
		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
            cross apply sys.dm_exec_sql_text(sql_handle) as qt	   
		where s.IS_USER_PROCESS = 1  and r.session_id <> @@spid
            and  ((@iswaitfor = 1 and wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
		order by r.cpu_time DESC
        
        
        
END
ELSE IF @plan = 1 -- query plan
BEGIN
   INSERT INTO dbo.MONITOR_SYSPROCESS 
    (reg_dt, sid, blocked, status, cpu, duration, dbname, objectname, query_text, last_wait_type
    ,login_name, host_name, program_name, dbid, objectid, total_elapsed_time, wait_type
    ,reads, writes, logical_reads, scheduler_id, tx_level
    ,wait_resource, open_tran_cnt, row_count, plan_handle, query_plan)
     select      getdate() as reg_dt
                ,r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
                ,r.last_wait_type
                ,s.login_name
    			,s.host_name
                ,s.program_name
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
                ,r.wait_type
    			,r.reads
    			,r.writes
    			,r.logical_reads
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
    			,r.plan_handle
    		    ,pt.query_plan
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                 cross apply sys.dm_exec_sql_text(sql_handle) as qt
                 cross apply sys.dm_exec_query_plan(r.plan_handle) as pt
    		where s.IS_USER_PROCESS = 1   and r.session_id <> @@spid
                and  ((@iswaitfor = 1 and wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
    		order by r.cpu_time DESC
END



RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO