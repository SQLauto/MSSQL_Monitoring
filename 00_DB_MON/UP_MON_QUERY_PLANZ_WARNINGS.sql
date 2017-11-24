use dbmon
go

/*************************************************************************  
* 프로시저명: dbo.UP_MON_QUERY_PLANZ_WARNINGS
* 작성정보	: 2014-12-15 BY CHOI BO RA
* 관련페이지:  
* 내용		:  쿼리 PLAN WARINGS 정보

* 수정정보	: 
**************************************************************************/
CREATE PROCEDURE dbo.UP_MON_QUERY_PLANZ_WARNINGS
	@date			datetime = null
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

/*BODY*/
if @date is null set @date =  getdate()

select top 1 @date = reg_date from db_mon_query_stats_v3 (nolock) 
where reg_date <= @date order by reg_date desc


select 
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
p.query_cost,
p.warnings,
s.query_text,
p.query_plan
from dbo.db_mon_query_stats_v3 s (nolock)   
 join  dbo.db_mon_query_plan_v3 p (nolock)  
  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
where s.reg_date = @date
	AND P.WARNINGS <> ''
order by s.reg_date desc, s.cpu_min desc 


