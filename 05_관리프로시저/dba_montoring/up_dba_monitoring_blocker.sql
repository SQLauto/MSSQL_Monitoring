SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitoring_blocker 
* 작성정보    : 2010-02-08 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitoring_blocker
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @eventinfo nvarchar(255)
declare @get_date  datetime
--declare
--        @lastwaittype    nchar(64),
--        @dbname          nchar(512),
--        @spid            smallint,
--        @blocked         smallint,
--        @cpu             int,
--        @physical_io     bigint,
--        @waittype        binary(20),
--        @waittime        int,
--        @waitresource    nchar(600),
--        @cmd             nchar(32),
--        @hostname        nchar(256),
--        @program_name    nchar(256),
--        @login_time      datetime,
--        @last_batch      datetime,
--        @sql_handle      binary(20),
--        @sql_handle_bk   binary(20),
--        @stmt_start      int,
--        @stmt_end        int,
--        @stmt_start_bk      int,
--        @stmt_end_bk       int,
--        @query_text      varchar(255),
--        @query_text_bk      varchar(255),
--        @objectid        int,
--        @objectid_bk     int,
--        @objectname      nchar(512),
--        @objectname_bk   nchar(512),
--        @dbid            int,
--        @dbid_bk         int,
--        @status          nchar(60),
--        @day             int,
--        @hour            int,
--        @minute          int,
--        @cnt           int,
--        @str           nvarchar(1000)
    

/* BODY */
--------------------------------------------------
-- 데이터 삭제
-------------------------------------------------
declare @min_value datetime, @max_value datetime, @new_value datetime, @now datetime

select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = 'PF__MONITOR_BLOCKER_REG_DT'



if @max_value <= GETDATE()
begin
	
	SET @new_value = DATEADD(day, 1, @max_value)

    ALTER TABLE MONITOR_BLOCKER SWITCH PARTITION 1 TO MONITOR_BLOCKER_SWITCH
    -- 데이터 삭제
    TRUNCATE TABLE MONITOR_BLOCKER_SWITCH
    
    ALTER PARTITION SCHEME PS__MONITOR_BLOCKER_REG_DT NEXT USED [PRIMARY]

    ALTER PARTITION FUNCTION PF__MONITOR_BLOCKER_REG_DT() MERGE RANGE (@min_value)

    ALTER PARTITION FUNCTION PF__MONITOR_BLOCKER_REG_DT() SPLIT RANGE (@new_value)
   
end

set @get_date = getdate()

insert into dbo.MONITOR_BLOCKER
    ( reg_dt, sid, blocked, status, bk_cpu, bk_dbname, bk_objectid, bk_objectname
     ,cpu, dbname, objectid, objectname, login_name, host_name, program_name
     ,last_wait_type,total_elapsed_time,reads,writes,logical_reads, wait_type, wait_resource
     ,tran_count)
select @get_dat as reg_dt
    ,m.session_id as spid, m.blocking_session_id as blocked 
    ,m.status ,b.cpu_time as bk_cpu
      -- blocker 정보
    ,db_name(bqt.dbid) as bk_dbname
    ,bqt.objectid as bk_objectid
    ,case when object_schema_name(bqt.objectid,qt.dbid) + '.' + object_name(bqt.objectid,qt.dbid) is not null 
        then object_schema_name(bqt.objectid,qt.dbid) + '.' + object_name(bqt.objectid,qt.dbid) 
        else (
                substring(bqt.text,b.statement_start_offset/2 + 1,
            			(case when b.statement_end_offset = -1
            			then len(convert(nvarchar(max), bqt.text)) * 2
            			else b.statement_end_offset end - b.statement_start_offset)/2)
               ) end as bk_objectname
     --당한 정보
    ,m.cpu_time as cpu, db_name(qt.dbid) as dbname, qt.objectid as objectid 
    ,case when object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) is not null 
        then object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) 
        else (
                substring(qt.text,m.statement_start_offset/2 + 1,
            			(case when m.statement_end_offset = -1
            			then len(convert(nvarchar(max), qt.text)) * 2
            			else m.statement_end_offset end - m.statement_start_offset)/2)
               ) end as objectname
    ,s.login_name, s.host_name, s.program_name
    ,m.last_wait_type ,m.total_elapsed_time, m.reads, m.writes, m.logical_reads, m.wait_type, m.wait_resource
    ,m.open_transaction_count  as tran_count
from sys.dm_exec_requests m with(nolock) 
    inner join sys.dm_exec_requests b with(nolock)  on ( m.blocking_session_id = b.session_id)
        -- m 이 기본 세션  정보, b가 블로킹 세션정보
    inner join sys.dm_exec_sessions s on m.session_id = s.session_id
    cross apply sys.dm_exec_sql_text(m.sql_handle) as qt      
	cross apply sys.dm_exec_sql_text(b.sql_handle) as bqt
where s.is_user_process = 1
     and m.session_id <> m.blocking_session_id -- 본인 제외
     and b.session_id <> b.blocking_session_id -- 본인 제외
    -- and b.blocking_session_id = 0             -- blocker 찾기
     

     
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO