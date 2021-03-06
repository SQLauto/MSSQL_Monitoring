CREATE PROCEDURE [dbo].[up_mon_collect_query_stats_daily_v3]  
 @date datetime = null  
AS  
SET NOCOUNT ON  

SET QUERY_GOVERNOR_COST_LIMIT 0
  
exec UP_SWITCH_PARTITION 'DB_MON_QUERY_STATS_DAILY_V2', 'REG_DATE'  

 
declare @from_date datetime, @to_date datetime
declare @wk_from_date datetime, @wk_to_date datetime
declare @total_cpu bigint  

  
if @date is null  
begin  
 set @from_date = convert(datetime, convert(char(10), dateadd(day, -1, getdate()), 121))  
 set @to_date = convert(datetime, convert(char(10), getdate(), 121))  
end  
else   
begin  
 set @from_date = convert(datetime, convert(char(10), @date, 121))  
 set @to_date = convert(datetime, convert(char(10), dateadd(day, 1, @date), 121))  
end  
  
if exists (select top 1 * from DB_MON_QUERY_STATS_DAILY_V2 (nolock) where reg_date = @from_date)   
begin  
 print '   . '  
 return  
end  

set @wk_from_date = CONVERT(char(10), @from_date, 121) + ' 09:00'
set @wk_to_date = CONVERT(char(10), @from_date, 121) + ' 19:00'


select  @total_cpu =SUM(cpu_min) from db_mon_query_stats_v3 with(nolock) 
where reg_date >= @from_date and reg_date < @to_date

insert into  DB_MON_QUERY_STATS_DAILY_V2
(
	reg_date, type, cpu_rate, db_name, object_name, db_id, object_id, statement_start, statement_end,set_options
	,cnt_day, cpu_day, reads_day, writes_day,duration_day, cpu_cnt, reads_cnt,  writes_cnt,duration_cnt
	,query_text
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'A'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu) *100) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
	,  query_text
from db_mon_query_stats_V3 with(nolock) where reg_date >= @from_date and reg_date < @to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options, query_text
ORDER BY  SUM(cpu_min)  desc




select  @total_cpu=SUM(cpu_min) from db_mon_query_stats_V3 with(nolock) 
where reg_date >= @wk_from_date and reg_date < @wk_to_date



insert into  DB_MON_QUERY_STATS_DAILY_V2 
(
	reg_date, type, cpu_rate, db_name, object_name, db_id, object_id, statement_start, statement_end,set_options
	,cnt_day, cpu_day, reads_day, writes_day,duration_day, cpu_cnt, reads_cnt,  writes_cnt,duration_cnt
	,query_text
	
)
select convert(nvarchar(10), max(reg_date), 121) , 'W'
	,  convert(numeric(4,2), ( SUM(cpu_min) * 1.00/ @total_cpu  ) *100.0) as cpu_rate
	,  DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options
	,  SUM(cnt_min) , SUM(cpu_min) , SUM(reads_min) , SUM(writes_min) ,SUM(duration_min) 
	,  AVG(cpu_cnt) , AVG(reads_cnt) , AVG(writes_cnt), AVG(duration_cnt) 
	,  query_text
from db_mon_query_stats_V3 with(nolock) where reg_date >= @wk_from_date and reg_date < @wk_to_date
GROUP BY DB_NAME, OBJECT_NAME, DB_ID, OBJECT_ID, statement_start, statement_end, set_options, query_text
ORDER BY  SUM(cpu_min) desc


