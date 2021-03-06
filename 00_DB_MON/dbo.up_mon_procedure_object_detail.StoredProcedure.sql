USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_procedure_object_detail]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************    
* 프로시저명  : dbo.[[up_mon_procedure_object_detail]]
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : [up_mon_procedure_object] 
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_object_detail]
 @object_name sysname = null,
 @date datetime = null
AS  
SET NOCOUNT ON  

declare @basedate datetime, @query_basedate datetime
declare @max int, @seq int
declare @statement_start int, @statement_end int, @set_options int


if @object_name is null
begin
	print '@object_name 이 입력되어야 합니다!!!'
	return
end

if @date is null set @date =  getdate()  

select @basedate = max(reg_date) from DB_MON_PROCEDURE_STATS (nolock) 


-- 프로시저 내역
select reg_date,  from_date, to_date,term, db_name, object_name, cached_time, cpu_rate
	, cnt_min,cpu_min, reads_min, writes_min,duration_min, sql_handle,plan_handle
	, cpu_cnt, reads_cnt, writes_cnt, duration_cnt
from DBMON.DBO.DB_MON_PROCEDURE_STATS  WITH(NOLOCK)
where reg_date = @basedate
 and object_name = @object_name

-- 상세 쿼리 내역

select @query_basedate = max(reg_date) from dbmon.dbo.DB_MON_QUERY_STATS_V3 with(nolock) 
where reg_date <= @date
	and object_name = @object_name

--select @query_basedate

select qs.db_name,  
	qs.object_name,  
	qs.reg_date as to_date,   
	qs.type,
	qs.term, 
	qs.set_options,  
	p.line_start,  
	p.line_end,  
	qs.cnt_min,  
	qs.cpu_rate,  
	qs.cpu_min,  
	qs.reads_min,  
	qs.writes_min,  
	qs.duration_min,  
	qs.cpu_cnt,  
	qs.reads_cnt,  
	qs.writes_cnt, 
	qs.duration_cnt, 
	convert(xml,p.query_plan) as query_plan, 
	qs.query_text,
	qs.sql_handle,
	qs.plan_handle,
	qs.statement_start,
	qs.statement_end,
	qs.create_date	
from dbmon.dbo.DB_MON_query_STATS_v3 as qs with(nolock)  
	left join  dbo.db_mon_query_plan_v3 p (nolock)  
	  on qs.plan_handle = p.plan_handle and qs.statement_start = p.statement_start and qs.statement_end = p.statement_end and qs.create_date = p.create_date  
where qs.reg_date = @query_basedate
 and qs.object_name = @object_name
order by qs.cpu_min desc

GO
