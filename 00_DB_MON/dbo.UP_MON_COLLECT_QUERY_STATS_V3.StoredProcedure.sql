
/* 2014-10-28 최보라 total_sum_cpu 변경 , wirte 값 추가 
	 2014-11-24 BY CHOI BO RA  query_hash,query_plan_hash 추가 
*/
CREATE PROCEDURE [dbo].[UP_MON_COLLECT_QUERY_STATS_V3]          
 @min_cpu bigint = 1000          
AS          
SET NOCOUNT ON          
          
exec up_switch_partition @table_name = 'DB_MON_QUERY_STATS_V3', @column_name = 'REG_DATE'    

          
declare @from_date datetime, @to_date datetime, @reg_date datetime                
declare @to_cpu bigint, @from_cpu bigint, @worker_time_min money              
declare @term int, @cpu_term numeric(18, 2)              
                
select @to_date = max(reg_date) from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)        
        
if exists (select top 1 * from DB_MON_QUERY_STATS_V3 (nolock) where reg_date = @to_date)        
begin        
 print '이미 저장된 시간대 입니다.!!!'        
 return        
end        
        
--select @TO_CPU = CPU_TOTAL               
--from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
--where reg_date = @TO_DATE               
                
select db_id, object_name, object_id, plan_handle, statement_start, statement_end, set_options, create_date
, cnt, cpu, writes, reads, duration, query_text,type , sql_handle,query_hash,query_plan_hash      
into #query_stats_to          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @to_date  

          
select @from_date = max(reg_date) from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock) where reg_date < @to_date                


--select @from_cpu = CPU_TOTAL               
--from DB_MON_QUERY_STATS_TOTAL_CPU with (nolock)               
--where reg_date = @from_date   

           
          
select plan_handle, statement_start, statement_end, set_options, create_date, cnt, cpu, writes, reads, duration    
into #query_stats_from          
from DB_MON_QUERY_STATS_TOTAL_V3 with (nolock)          
where reg_date = @from_date          
          
set @term = datediff(second, @from_date, @to_date)          
    

select  @cpu_term= sum(case when term > 30 then sum_cpu_gap * 60 / term else -1 end ) 
from 
	(
	select  sum(a.cpu - isnull(b.cpu, 0))  as sum_cpu_gap
		, case when datediff(second, @from_date, a.create_date) <= 0 then @term else datediff(second, a.create_date, @to_date) end as term         
	from #query_stats_to a with (nolock)           
	 left join #query_stats_from b with (nolock)           
	  on a.plan_handle = b.plan_handle and a.statement_start = b.statement_start and a.statement_end = b.statement_end and a.create_date = b.create_date
	group by a.cpu, b.cpu, a.create_date
	) AS T



       
insert DB_MON_QUERY_STATS_V3          
( reg_date,          
 from_date,          
 db_name,          
 object_name,
 type,         
 db_id,       
 object_id,        
 set_options,          
 statement_start,          
 statement_end,          
 create_date,          
 cnt_min,          
 cpu_rate,          
 cpu_min,          
 reads_min, 
 writes_min,         
 duration_min,          
 cpu_cnt,          
 reads_cnt, 
 writes_cnt,         
 duration_cnt,          
 term,          
 plan_handle,
 cnt_total,
 cpu_total,
 reads_total,
 writes_total,
 duration_total,
 query_text,
 sql_handle, 
 query_hash,
 query_plan_hash
 )          
select         
 reg_date,        
 from_date,        
 db_name,        
 case when object_name is null then '' else object_name end,
 type,
 db_id,       
 object_id,      
 set_options,        
 statement_start,        
 statement_end,        
 create_date,        
 case when term > 30 then cnt_gap * 60 / term else - 1 end as cnt_min, 
 convert(numeric(6,2),  (case when term > 30 then cpu_gap * 60 / term else -1  end ) / @cpu_term * 100 )   as cpu_rate,
 --convert(numeric(6, 2), cpu_gap* 1.0 /@cpu_term * 100) as cpu_rate,        
 case when term > 30 then cpu_gap * 60 / term else -1 end as cpu_min,  
 case when term > 30 then reads_gap * 60 / term else - 1 end as reads_min,  
 case when term > 30 then writes_gap * 60 / term else - 1 end as writes_min, 
 case when term > 30 then duration_gap * 60 / term end as duration_min,  
 case when cnt_gap = 0 then -1 else cpu_gap / cnt_gap end cpu_cnt,        
 case when cnt_gap = 0 then -1 else reads_gap / cnt_gap end reads_cnt,
case when cnt_gap = 0 then -1 else writes_gap / cnt_gap end writes_cnt, 
 case when cnt_gap = 0 then -1 else duration_gap / cnt_gap end duraiton_cnt,  
 term,        
 plan_handle,
 cnt_gap,
 cpu_gap,
 reads_gap,
 writes_gap,
 duration_gap,
 query_text,
 sql_handle ,
 query_hash,
 query_plan_hash  
from         
(        
 select         
  @to_date as reg_date,        
  @from_date as from_date,         
  isnull(db_name(a.db_id), 'PREPARE') as db_name,        
  a.object_name,
  a.type,        
  a.db_id,       
  a.object_id,        
  a.set_options as set_options,        
  a.statement_start as statement_start,        
  a.statement_end as statement_end,        
  a.create_date as create_date,        
  a.cnt - isnull(b.cnt, 0) as cnt_gap,        
  a.cpu - isnull(b.cpu, 0) as cpu_gap,        
  a.reads - isnull(b.reads, 0) as reads_gap,   
  a.writes - isnull(b.writes, 0) as writes_gap,         
  a.duration - isnull(b.duration, 0) as duration_gap,        
  case when datediff(second, @from_date, a.create_date) <= 0 then @term else datediff(second, a.create_date, @to_date) end as term,        
  a.plan_handle,        
  a.query_text,
  A.sql_handle,
  a.query_hash,
  a.query_plan_hash
 from #query_stats_to a with (nolock)         
  left join #query_stats_from b with (nolock)         
   on a.plan_handle = b.plan_handle and a.statement_start = b.statement_start and a.statement_end = b.statement_end and a.create_date = b.create_date        
 ) a        
where (cnt_gap <> 0 or cpu_gap <> 0)        
  and cpu_gap > @min_cpu * @term / 60        
order by cpu_gap desc        


          
drop table #query_stats_to          
drop table #query_stats_from 

