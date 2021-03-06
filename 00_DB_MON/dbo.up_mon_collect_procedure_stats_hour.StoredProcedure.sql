USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_procedure_stats_hour]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_procedure_stats_hour
* 작성정보    : 2011-01-14 수정 top 1로 변경
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats_hour]      
AS        
        
set nocount on        
        
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS_HOUR', @column_name = 'REG_DATE'           
        
declare @from_date datetime, @to_date datetime, @reg_date datetime        
declare @to_worker_time bigint, @from_worker_time bigint, @worker_time_min money    
declare @term int      
        
select top 1 @to_date = reg_date 
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
order by  reg_date desc
    
if exists (select top 1 * from DB_MON_PROCEDURE_STATS_HOUR (nolock) 
    where reg_date >= dateadd(hour, -2, @to_date))    
begin    
 print '이미 해당 데이터가 존재합니다.'    
 return    
end    
    
select top 1 @to_date = reg_date
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
where reg_date < convert(datetime, convert(char(13), @to_date, 121) + ':00') 
order by reg_date desc

   
    
select @to_worker_time = SUM(worker_time)       
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)       
where reg_date = @to_date    
        
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, logical_writes, elapsed_time        
into #resource_to      
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)        
where reg_date = @to_date      
        
select  top  1 @from_date = reg_date
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock) 
where reg_date < convert(datetime, convert(char(13), @to_date, 121) + ':00')   
order by reg_date desc 
      
select @from_worker_time = SUM(worker_time)       
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)       
where reg_date = @from_date       
  and sql_handle in (select sql_handle from #resource_to )      
      
select sql_handle, plan_handle, db_id, object_id, cached_time, execution_count as count, worker_time, logical_reads, logical_writes, elapsed_time        
into #resource_from        
from DB_MON_PROCEDURE_STATS_TOTAL with (nolock)        
where reg_date = @from_date      
      
set @term = DATEDIFF(second, @from_date, @to_date)    
set @worker_time_min = @to_worker_time - @from_worker_time    
    
--select @from_date, @to_date, @term, @worker_time_min    
      
set @reg_date = convert(datetime, convert(char(13), @to_date, 121) + ':00')    

      
insert DB_MON_PROCEDURE_STATS_HOUR (      
 reg_date, db_id, object_id, db_name, object_name, cached_time, from_date, to_date,       
 cnt_min, cpu_rate, cpu_min, reads_min, writes_min, duration_min, cpu_cnt, reads_cnt, writes_cnt, duration_cnt, sql_handle, term)      
select @reg_date as reg_date      
     , a.DB_ID as db_id    
     , a.OBJECT_ID as object_id      
     , DB_NAME(a.db_id) as db_name      
  , OBJECT_NAME(a.object_id, a.db_id) as object_name      
  , a.cached_time      
  , @from_date as from_date      
  , @to_date as to_date      
  , (a.count - isnull(b.count, 0)) * 60 / @term as cnt_min    
  , case when @worker_time_min > 0 
    then convert(money, (a.worker_time - ISNULL(b.worker_time, 0))) * 100 / @worker_time_min else 0
     end as cpu_rate      
  , (a.worker_time - ISNULL(b.worker_time, 0)) * 60 / @term as cpu_min      
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) * 60 / @term as reads_min   
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) * 60 / @term as writes_min      
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) * 60 / @term as duration_min      
  , (a.worker_time - ISNULL(b.worker_time, 0)) / (a.count - ISNULL(b.count, 0)) as cpu_cnt      
  , (a.logical_reads - ISNULL(b.logical_reads, 0)) / (a.count - ISNULL(b.count, 0)) as reads_cnt   
  , (a.logical_writes - ISNULL(b.logical_writes, 0)) / (a.count - ISNULL(b.count, 0)) as wriates_cnt      
  , (a.elapsed_time - ISNULL(b.elapsed_time, 0)) / (a.count - ISNULL(b.count, 0)) as duration_cnt      
  , a.sql_handle      
  , @term as term      
from #resource_to A with (nolock)                     
 left join #resource_from b with (nolock) on a.sql_handle  = b.sql_handle and a.plan_handle = b.plan_handle      
where (a.count - b.count) > 0        
order by cpu_rate desc   
option (maxdop 1)   
   
        
drop table #resource_from 
drop table #resource_TO

GO
