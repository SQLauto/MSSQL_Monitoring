USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_procedure_stats]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats]  
AS    
    
set nocount on    
    
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS', @column_name = 'REG_DATE'       
    
declare @from_date datetime, @to_date datetime, @reg_date datetime    
declare @to_worker_time bigint, @from_worker_time bigint, @worker_time_min money  
declare @term int  
    
select @to_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    

if exists (select top 1 * from DB_MON_PROCEDURE_STATS (nolock) where reg_date >= @to_date) 
begin
	print '이미 해당 데이터가 존재합니다.'
	return
end
    
select @to_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @to_date
    
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time, logical_writes 
into #resource_to  
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @to_date  
    
select @from_date = max(reg_date) from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) where reg_date < @to_date    
  
select @from_worker_time = SUM(worker_time)   
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)   
where reg_date = @from_date   
  and sql_handle in (select sql_handle from #resource_to )  
  
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, elapsed_time, logical_writes
into #resource_from    
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)    
where reg_date = @from_date  
  
set @term = DATEDIFF(second, @from_date, @to_date)
set @worker_time_min = @to_worker_time - @from_worker_time

select @from_date, @to_date, @term, @worker_time_min
  
set @reg_date = GETDATE()    
 
  
insert DB_MON_PROCEDURE_STATS (  
 reg_date, db_id, object_id, db_name, object_name, cached_time, from_date, to_date,   
 cnt_min, cpu_rate, cpu_min, reads_min, writes_min,duration_min, cpu_cnt, reads_cnt, writes_cnt, duration_cnt, sql_handle, term, plan_handle)  
select @reg_date as reg_date  
     , a.DB_ID as db_id
     , a.OBJECT_ID as object_id  
     , DB_NAME(a.db_id) as db_name  
  , OBJECT_NAME(a.object_id, a.db_id) as object_name  
  , a.cached_time  
  , @from_date as from_date  
  , @to_date as to_date  
  , (a.count - isnull(b.count, 0)) * 60 / @term as cnt_min
  , round(case when @worker_time_min > 0 then convert(money, (a.worker_time - ISNULL(b.worker_time, 0))) * 100 / @worker_time_min else 0 end,2) as cpu_rate  
  , (a.worker_time - ISNULL(b.worker_time, 0)) * 60 / @term as cpu_min  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) * 60 / @term as reads_min  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) * 60 / @term as writes_min 
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) * 60 / @term as duration_min  
  , (a.worker_time - ISNULL(b.worker_time, 0)) / (a.count - ISNULL(b.count, 0)) as cpu_cnt  
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) / (a.count - ISNULL(b.count, 0)) as reads_cnt  
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) / (a.count - ISNULL(b.count, 0)) as writes_cnt  
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) / (a.count - ISNULL(b.count, 0)) as duration_cnt  
  , a.sql_handle  
  , @term as term  
  , a.plan_handle
from #resource_to A with (nolock)                 
 left join #resource_from b with (nolock) on a.sql_handle  = b.sql_handle and a.plan_handle = b.plan_handle  
where (a.count - b.count) > 0    
order by cpu_rate desc  
  
    
drop table #resource_from   
drop table #resource_to 


GO
