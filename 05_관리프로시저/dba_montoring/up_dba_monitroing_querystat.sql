SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitroing_querystat 
* 작성정보    : 2010-02-25 by choi bo ra
* 관련페이지  :  
* 내용        : 2005 이상 용 syscacheobjects 적재
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitroing_querystat
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @reg_dt datetime
/* BODY */
--------------------------------------------------
-- 데이터 삭제
-------------------------------------------------
declare @min_value datetime, @max_value datetime, @new_value datetime

select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = 'PF__MONITOR_QUERYSTAT__REG_DT'



if @max_value <= GETDATE()
begin
	
	SET @new_value = DATEADD(day, 1, @max_value)

    ALTER TABLE MONITOR_QUERYSTAT SWITCH PARTITION 1 TO MONITOR_QUERYSTAT_SWITCH
    -- 데이터 삭제
    TRUNCATE TABLE MONITOR_QUERYSTAT_SWITCH
    
    ALTER PARTITION SCHEME PS__MONITOR_QUERYSTAT__REG_DT NEXT USED [PRIMARY]

    ALTER PARTITION FUNCTION PF__MONITOR_QUERYSTAT__REG_DT() MERGE RANGE (@min_value)

    ALTER PARTITION FUNCTION PF__MONITOR_QUERYSTAT__REG_DT() SPLIT RANGE (@new_value)
   
end

SET @reg_dt = getdate()

insert dbo.MONITOR_QUERYSTAT 
    (reg_dt, sql_handle, dbid, objectid, dbname, objectname, create_date,
	 distinct_cnt, cnt, execution_count, total_worker_time, total_physical_reads, 
	 total_logical_writes, total_logical_reads, 
	total_clr_time, total_elapsed_time)
select @reg_dt, qs.sql_handle, qt.dbid, qt.objectid, db_name(qt.dbid)
    ,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) as objectname
    ,create_date,distinct_cnt, cnt, execution_count, total_worker_time, 
	total_physical_reads, total_logical_writes, total_logical_reads, 
	total_clr_time, total_elapsed_time
from (    
 select
   sql_handle    
   , count(distinct statement_start_offset) as distinct_cnt    
   , max(creation_time) as create_date    
   , max(execution_count) as cnt    
   , sum(execution_count)     as  execution_count          
   , sum(total_worker_time)     as  total_worker_time          
   , sum(total_physical_reads)    as  total_physical_reads          
   , sum(total_logical_writes)    as  total_logical_writes          
   , sum(total_logical_reads)    as  total_logical_reads          
   , sum(total_clr_time)     as  total_clr_time          
   , sum(total_elapsed_time)    as  total_elapsed_time       
 from sys.dm_exec_query_stats     
 where convert(varbinary, left(sql_handle, 1)) = 0x03  -- 프로시저만
 group by sql_handle    
 ) qs     
 cross apply sys.dm_exec_sql_text (qs.sql_handle) as qt    
order by total_worker_time desc    


RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



/*************************************************************************  
* 프로시저명  : dbo.up_dba_monitroing_querystat_term 
* 작성정보    : 2010-02-25 by choi bo ra
* 관련페이지  :  
* 내용        : 2005이상 용 syscacheobjects 비교
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_monitroing_querystat_term
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

DECLARE @reg_dt datetime
declare @max_date datetime
/* BODY */
--------------------------------------------------
-- 데이터 삭제
-------------------------------------------------
declare @min_value datetime, @max_value datetime, @new_value datetime

select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = 'PF__MONITOR_QUERYSTAT_TERM__REG_DT'



if @max_value <= GETDATE()
begin
	
	SET @new_value = DATEADD(day, 1, @max_value)

    ALTER TABLE MONITOR_QUERYSTAT_TERM SWITCH PARTITION 1 TO MONITOR_QUERYSTAT_TERM_SWITCH
    -- 데이터 삭제
    TRUNCATE TABLE MONITOR_QUERYSTAT_TERM_SWITCH
    
    ALTER PARTITION SCHEME PS__MONITOR_QUERYSTAT_TERM__REG_DT NEXT USED [PRIMARY]

    ALTER PARTITION FUNCTION PF__MONITOR_QUERYSTAT_TERM__REG_DT() MERGE RANGE (@min_value)

    ALTER PARTITION FUNCTION PF__MONITOR_QUERYSTAT_TERM__REG_DT() SPLIT RANGE (@new_value)
   
end

SET @reg_dt = getdate()



--========================================
-- 진행
--========================================  
select @max_date = max(reg_dt) from MONITOR_QUERYSTAT with (nolock)  
  
select sql_handle, dbid, objectid, dbname, [reg_dt], create_date, objectname, cnt, total_worker_time, total_logical_reads, total_elapsed_time  
into #resource_to  
from MONITOR_QUERYSTAT with (nolock)  
where reg_dt = @max_date  
  
select @max_date = max(reg_dt) from MONITOR_QUERYSTAT with (nolock) where reg_dt < @max_date  
  
select sql_handle, dbid, objectid, dbname, [reg_dt], create_date, objectname, 
cnt, total_worker_time, total_logical_reads, total_elapsed_time  
into #resource_from  
from MONITOR_QUERYSTAT with (nolock)  
where reg_dt = @max_date  
  
  
 insert into MONITOR_QUERYSTAT_TERM 
    (reg_dt, dbname, objectname, from_date, to_date, create_date
    , cnt_min, worker_time_min, logical_reads_min, elapsed_time_min
    , worker_time_cnt, logical_reads_cnt, elapsed_time_cnt, term)  
select @reg_dt, a.dbname, a.objectname, b.reg_dt, a.reg_dt, a.create_date,  
 (a.cnt - isnull(b.cnt, 0)) * 60 / datediff(second, b.reg_dt, a.reg_dt)  as cnt_min,          
 case when a.reg_dt is not null 
        then (a.total_worker_time - isnull(b.total_worker_time, 0)) * 60 / datediff(second, b.reg_dt , a.reg_dt) 
            else 0 end as worker_time_min,          
 case when a.reg_dt is not null then (a.total_logical_reads - isnull(b.total_logical_reads, 0)) * 60 / datediff(second, b.reg_dt, a.reg_dt) else 0 end as logical_reads_min,          
 case when a.reg_dt is not null then (a.total_elapsed_time - isnull(b.total_elapsed_time, 0)) * 60 / datediff(second, b.reg_dt, a.reg_dt) else 0 end as elapsed_time_min,          
 (a.total_worker_time - isnull(b.total_worker_time, 0)) / (a.cnt - isnull(b.cnt, 0)) as worker_time_cnt,          
 (a.total_logical_reads - isnull(b.total_logical_reads, 0)) / (a.cnt - isnull(b.cnt, 0)) as logical_reads_cnt,          
 (a.total_elapsed_time - isnull(b.total_elapsed_time, 0)) / (a.cnt - isnull(b.cnt, 0)) as elapsed_time_cnt,  
 datediff(second, b.reg_dt, a.reg_dt)  
from #resource_to A with (nolock)               
 left join #resource_from b with (nolock) on a.objectname  = b.objectname and a.dbname = b.dbname  
where (a.cnt - b.cnt) > 0  
order by 8
  
drop table #resource_from  
drop table #resource_to  
  
RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
