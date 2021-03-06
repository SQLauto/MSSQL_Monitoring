USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_sp_rate]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* : dbo.up_mon_query_stats_sp_rate
* 	: 2013-07-16 by choi bo ra
* :  
* 		:    sp   
* 	:
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_query_stats_sp_rate]
	 @type   varchar(10) = 'cpu',  -- cnt, i/o, 
	 @from_date	datetime, 
	 @sp_name sysname

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE*/  
declare @basedate datetime, @total bigint
select @basedate = max(reg_date) from db_mon_query_stats_v3 (nolock)  
where reg_date <= @from_date

if @type = 'cpu'
begin
	

	
	select s.rank,
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
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by cpu_min desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end
else if @type = 'cnt'
begin
	
		select @total = sum(cnt_min) from  db_mon_query_stats_v3 (nolock)  where reg_date = @basedate 
		
		select s.rank,  convert(decimal(5,1), s.cnt_min *1.0 /@total * 100 ) as cnt_rate,
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
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by cnt_min desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end
else if @type = 'i/o'
begin
	
		select @total = sum(reads_min) from  db_mon_query_stats_v3 (nolock)  where reg_date = @basedate 
		
		
		select s.rank,  convert(decimal(5,1), s.reads_min *1.0 /@total * 100.0 ) as reads_rate,
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
		s.plan_handle,
		s.statement_start,
		s.statement_end,
		s.create_date, 
		s.query_text,
		p.query_plan
	from
	(select rank() over (order by reads_min  desc) as rank 
		,s.*
	from dbo.db_mon_query_stats_v3 s (nolock)  
	where reg_date = @basedate
	) as s
	 left join  dbo.db_mon_query_plan_v3 p (nolock)  
		  on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date  
	where s.object_name  = @sp_name
	
end

GO
