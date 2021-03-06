USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_top_duration]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[up_mon_query_stats_top_duration]
 @date datetime = null,  
 @rowcount int = 20  
AS  

SET NOCOUNT ON  
  
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc
  

select top (@rowcount)  
s.db_name,  
s.object_name,  
s.reg_date as to_date,  
s.type,    
s.term, 
s.set_options,  
p.line_start,  
p.line_end,  
s.cnt_min,  
s.cpu_rate,  
s.cpu_min,  
s.reads_min,  
s.writes_min,
s.duration_min,  
s.cpu_cnt,  
s.reads_cnt,  
s.writes_cnt,
s.duration_cnt,  
s.statement_start,
s.statement_end,
s.create_date, 
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
left join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
--outer apply dbo.fn_getobjectline(s.plan_handle, s.statement_start, s.statement_end) f  
where s.reg_date = @date  
order by s.reg_date desc, s.duration_min desc 

GO
