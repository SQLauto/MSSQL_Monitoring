USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_object_excel]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 2010-08-25 11:42 */  
--   seq   
-- plan     
-- date parameter   
--      
  
CREATE PROCEDURE [dbo].[up_mon_query_stats_object_excel]       
 @object_name sysname = null,  
 @date datetime = null,  
 @is_plan tinyint = 1  
AS      
      
set nocount on      
      
declare @base_time datetime      
declare @before_10min datetime      
declare @before_1day datetime      
declare @before_1week datetime      
    
declare @base_time_from datetime      
declare @before_10min_from datetime      
declare @before_1day_from datetime      
declare @before_1week_from datetime      
      
declare @proc_info table (      
 seq int identity(1, 1) primary key,      
 db_name varchar(32),      
 plan_handle varbinary(64),      
 statement_start int,      
 statement_end int      
)      
      
declare @max int, @seq int      
declare @db_name varchar(32), @statement_start int, @statement_end int, @plan_handle varbinary(64)      
      
declare @proc table (      
 base_time_type int,      
 plan_handle varbinary(64),      
 create_date datetime,      
 cnt_min bigint,      
 cpu_min bigint,      
 reads_min bigint,      
 duration_min bigint,      
 cpu_cnt bigint,      
 reads_cnt bigint,      
 duration_cnt bigint      
)      
      
declare @proc_pivot table (      
 seq int identity(1, 1) primary key,      
 type varchar(20),      
 base_date bigint,      
 before_10min bigint,      
 gap_10min numeric(5, 2),      
 before_1day bigint,      
 gap_1day numeric(5, 2),      
 before_1week bigint,      
 gap_1week numeric(5, 2)      
)      
    
declare @excel table (    
 seq int identity(1, 1) primary key,     
 col1 varchar(1000) default '',    
 col2 varchar(1000) default '',    
 col3 varchar(1000) default '',    
 col4 varchar(1000) default '',    
 col5 varchar(1000) default '',    
 col6 varchar(1000) default '',    
 col7 varchar(1000) default '',    
 col8 varchar(1000) default '',    
 col9 varchar(1000) default '',     
 col10 varchar(1000) default '',     
 col11 varchar(1000) default '',     
 col12 varchar(1000) default '',     
 col13 varchar(1000) default '',     
 col14 varchar(1000) default '',     
 col15 varchar(1000) default ''     
)    
      
if @object_name is null       
begin      
 print '@object_name    !!!'      
 return      
end      
  
if @date is null set @base_time = getdate()      
else set @base_time = @date  
      
select @base_time = max(reg_date), @base_time_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)       
where reg_date <= @base_time      
      
select @before_10min = max(reg_date), @before_10min_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(minute, -10, @base_time))      
      
select @before_1day = max(reg_date), @before_1day_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(day, -1, @base_time))      
      
select @before_1week = max(reg_date), @before_1week_from = max(from_date) from dbo.db_mon_query_stats_v3 (nolock)      
where reg_date <= dateadd(minute, 2, dateadd(day, -6, @base_time))      
    
insert @excel (col2, col3) values ('from date', 'to date')    
    
insert @excel (col1, col2, col3)    
select 'now ' as ' ', convert(char(16), @base_time_from, 121) as 'from date', convert(char(16),@base_time, 121) as 'to date'    
union all    
select 'before 10 min' as ' ', convert(char(16), @before_10min_from, 121) as 'from date', convert(char(16),@before_10min, 121) as 'to date'    
union all    
select 'before 1 day' as ' ', convert(char(16), @before_1day_from, 121) as 'from date', convert(char(16),@before_1day, 121) as 'to date'    
union all    
select 'before 1 week' as ' ', convert(char(16), @before_1week_from, 121) as 'from date', convert(char(16),@before_1week, 121) as 'to date'    
  
insert @excel (col1) values ('')    
      
insert @proc_info (db_name, statement_start, statement_end, plan_handle)      
select db_name, statement_start, statement_end, plan_handle      
from dbo.db_mon_query_stats_v3 (nolock)       
where reg_date = @base_time and object_name = @object_name      
order by statement_start      
      
select @max = @@rowcount, @seq = 1      
      
while @seq <= @max      
begin      
      
 select @db_name = db_name, @statement_start = statement_start, @statement_end = statement_end, @plan_handle = plan_handle      
 from @proc_info a       
 where seq = @seq      
     
 insert @excel (col1, col4, col5, col6, col7, col8, col10, col12, col14)    
 values ('object name', 'db name', 'line start', 'line end', 'statement start', 'statement end', 'cnt / min', 'cpu / min', 'reads / min')    
/*     
 insert @excel (col1, col4, col5, col6, col7, col8)    
 select     
 @object_name as object_name,     
 @db_name as db_name,     
 convert(varchar(10), line_start),     
 convert(varchar(10), line_end),     
 convert(varchar(10), @statement_start),     
 convert(varchar(10), @statement_end)    
 from dbo.fn_getobjectline(@plan_handle, @statement_start, @statement_end)      
*/   
 insert @excel (col1, col4, col5, col6, col7, col8)  
 select top 1   
 @object_name as object_name,  
 @db_name as db_name,  
 convert(varchar(10), line_start),  
 convert(varchar(10), line_end),  
 convert(varchar(10), @statement_start),  
 convert(varchar(10), @statement_end)  
 from db_mon_query_plan_v3 (nolock)   
 where plan_handle = @plan_handle and statement_start = @statement_start and statement_end = @statement_end  
 order by create_date desc   
   
 insert @excel (col1)   
 select convert(varchar(140), dbo.fn_getquerytext(@plan_handle, @statement_start, @statement_end))  
     
 insert @excel (col1) values ('')    
       
      
 set @seq = @seq + 1      
      
 insert @proc (base_time_type, plan_handle, create_date, cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt)      
 select       
  case when reg_date = @base_time then 0       
    when reg_date = @before_10min then 1      
    when reg_date = @before_1day then 2      
    when reg_date = @before_1week then 3      
  end,      
  plan_handle, create_date      
   , cnt_min, cpu_min, reads_min, duration_min, cpu_cnt, reads_cnt, duration_cnt      
 from dbo.db_mon_query_stats_v3 (nolock)       
 where object_name = @object_name and (reg_date in (@base_time, @before_10min, @before_1day, @before_1week))      
   and statement_start = @statement_start and statement_end = @statement_end      
      
-- insert @proc_pivot (type, base_date, before_10min, gap_10min, before_1day, gap_1day, before_1week, gap_1week)      
    
 insert @excel (col2, col3, col4, col5, col6, col7, col8)    
 values ('now', 'before 10 min', '10 min gap', 'before 1 day', '1 day gap', 'before 1 week', '1 week gap')    
     
 insert @excel (col1, col2, col3, col4, col5, col6, col7, col8)    
 select       
  case when cd = 0 then 'cnt / min'      
    when cd = 1 then 'cpu / min'      
    when cd = 2 then 'reads / min'      
    when cd = 3 then 'duration / min'      
    when cd = 4 then 'cpu / cnt'      
    when cd = 5 then 'reads / cnt'      
    when cd = 6 then 'duration / cnt'      
  end as ' ',      
  convert(varchar(20), base) as [now] ,      
  convert(varchar(20),m20) as 'before 10 min', convert(varchar(20), case when m20 = 0 then 0 else convert(numeric(10, 2), (base - m20) * 100 / convert(numeric(18, 2), m20)) end) as 'gap (10 min)',      
  convert(varchar(20),d1) as 'before 1 day' , convert(varchar(20), case when d1 = 0 then 0 else convert(numeric(10, 2), (base - d1) * 100 / convert(numeric(18, 2), d1)) end) as 'gap (1 day)',      
  convert(varchar(20),w1) as 'before 1 week', convert(varchar(20), case when w1 = 0 then 0 else convert(numeric(10, 2), (base - w1) * 100 / convert(numeric(18, 2), w1)) end) as 'gap (1 week)'      
 from (      
  select 0 as cd,       
   sum(case when base_time_type = 0 then cnt_min else 0 end) as base,      
   sum(case when base_time_type = 1 then cnt_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then cnt_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then cnt_min else 0 end) as w1      
  from @proc      
  union all      
  select 1 as cd,       
   sum(case when base_time_type = 0 then cpu_min else 0 end) as base,      
   sum(case when base_time_type = 1 then cpu_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then cpu_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then cpu_min else 0 end) as w1      
  from @proc      
  union all      
  select 2 as cd,       
   sum(case when base_time_type = 0 then reads_min else 0 end) as base,      
   sum(case when base_time_type = 1 then reads_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then reads_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then reads_min else 0 end) as w1      
  from @proc        
  union all      
  select 3 as cd,       
   sum(case when base_time_type = 0 then duration_min else 0 end) as base,      
   sum(case when base_time_type = 1 then duration_min else 0 end) as m20,      
   sum(case when base_time_type = 2 then duration_min else 0 end) as d1,      
   sum(case when base_time_type = 3 then duration_min else 0 end) as w1      
  from @proc        
  union all      
  select 4 as cd,       
   sum(case when base_time_type = 0 then cpu_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then cpu_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then cpu_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then cpu_cnt else 0 end) as w1      
  from @proc          
  union all      
  select 5 as cd,       
   sum(case when base_time_type = 0 then reads_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then reads_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then reads_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then reads_cnt else 0 end) as w1      
  from @proc         
  union all      
  select 6 as cd,       
   sum(case when base_time_type = 0 then duration_cnt else 0 end) as base,      
   sum(case when base_time_type = 1 then duration_cnt else 0 end) as m20,      
   sum(case when base_time_type = 2 then duration_cnt else 0 end) as d1,      
   sum(case when base_time_type = 3 then duration_cnt else 0 end) as w1      
  from @proc         
 ) a      
    
 insert @excel (col1) values ('')       
  
 if @is_plan = 1        
 begin  
     
  insert @excel (col2) values ('view plan info')      
  
  insert @excel (col1, col2)      
  select a.name,    
  isnull('exec dbmon.dbo.up_mon_query_plan_info @plan_handle = ' + dbo.fnc_hexa2decimal(plan_handle) + ', @create_date = ''' + convert(varchar(23), create_date, 121) + '''' + ', @statement_start = '   
  + convert(varchar(10), @statement_start) + ', @statement_end = ' + convert(varchar(10), @statement_end), '')  as view_plan        
  from (    
   select 0 as type, 'now' as name    
   union all    
   select 1 as type, 'before 10 min' as name    
   union all    
   select 2 as type, 'before 1 day' as name    
   union all    
   select 3 as type, 'before 1 week' as name    
  ) a left join @proc b on a.type = b.base_time_type    
  order by a.type    
      
  insert @excel (col1) values ('')    
  
 end   
      
 delete  @proc    
    
end      
    
    
select col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12, col13, col14, col15 from @excel order by seq

GO
