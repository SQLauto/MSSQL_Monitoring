USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_change]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* : dbo.up_mon_query_plan_change
* 	: 2013-07-19 by choi bo ra
* :  
* 		: exec dbo.up_mon_query_plan_change  '', ''-- 30
* 	:    query plan  
			  2014-10-28 by choi bo ra V3 
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_query_plan_change]
 	@reg_date 	datetime =null	, 
 	@duration 	int = 30	

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
declare @pre_reg_date datetime , @pre_pre_reg_date datetime

 
if @reg_date is null set @reg_date = getdate()

select @reg_date = max(reg_date) from dbmon.dbo.DB_MON_QUERY_PLAN_V3 with(nolock) where reg_date <= @reg_date
select @pre_reg_date = max(reg_date) from dbmon.dbo.DB_MON_QUERY_PLAN_V3 with(nolock) where reg_date < dateadd(mi, -1*@duration,@reg_date );

--select @reg_date, @pre_reg_date



WITH QUERY_PLAN ( rank, create_date, statement_start,statement_end
				,plan_handle,line_start, line_end ,query_plan, object_name,set_options)
AS 
(
	select  rank() over (partition by p1.object_name , p1.statement_start, p1.statement_end order by p1.create_date desc) as rank
		, p1.create_date,  p1.statement_start, p1.statement_end, p1.plan_handle , p1.line_start, p1.line_end, p1.query_plan
		, p1.object_name, p1.set_options
	from 
	(select  distinct db_name, object_name  from  DB_MON_QUERY_PLAN_V3 with(nolock)
		 where reg_date <= @reg_date and reg_date > @pre_reg_date ) as p 
		join  DB_MON_QUERY_PLAN_V3 as p1 with(nolock) on p1.object_name = p.object_name and p1.db_name = p.db_name 
	where p1.reg_date <= @reg_date and p1.reg_date >= dateadd(dd, -7, @reg_date)
)
SELECT  
		DB_NAME,
		object_name, 
		to_date,
		type,
		create_date,   	   
		set_options,  
		line_start,  
		line_end,  
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
		plan_handle,
		query_text,
		query_plan,
		statement_start,
		statement_end		
FROM 
(
	select RANK () OVER( PARTITION BY S.DB_NAME, S.OBJECT_NAME, P.CREATE_DATE ORDER BY S.REG_DATE DESC) AS RANK,  s.db_name,  
		s.object_name, 
		s.reg_date as to_date,
		s.type,
		s.create_date,   	   
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
		s.query_text,
		p.query_plan, 
		s.plan_handle,
		s.statement_start,
		s.statement_end		
	from QUERY_PLAN as p with(nolock) 
		join db_mon_query_stats_v3 as s with(nolock) 
			on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where p.rank <=2  
) AS M  WHERE RANK = 1
order by  M.object_name, M.LINE_START, M.LINE_END, M.CREATE_DATE DESC

GO
