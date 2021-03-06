USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_procedure_top_duration]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************    
* 프로시저명  : dbo.up_mon_procedure_top_duration 
* 작성정보    : 2014-10-29 by choi bo ra
* 관련페이지  :   
* 내용        : 프로시저 정보 
* 수정정보    : up_mon_procedure_top_duration
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_procedure_top_duration]
 @date datetime = null,  
 @rowcount int = 20  
AS  
SET NOCOUNT ON  

if @date is null set @date =  getdate()

select top 1 @date = reg_date from DB_MON_PROCEDURE_STATS (nolock) 
where reg_date <= @date order by reg_date desc
  
select top (@rowcount)  
	s.db_name,  
	s.object_name,  
	s.reg_date as to_date,   
	s.term, 
	s.cnt_min,  
	s.cpu_rate,  
	s.cpu_min,  
	s.reads_min, 
	s.writes_min ,
	s.duration_min,  
	s.cpu_cnt,  
	s.reads_cnt, 
	s.writes_cnt, 
	s.duration_cnt,  
	s.cached_time,   
--	p.query_plan,
	s.sql_handle
	from dbo.DB_MON_PROCEDURE_STATS s (nolock)   
		--cross apply sys.dm_exec_query_plan (s.plan_handle) as p
	where s.reg_date = @date  
	order by  s.duration_cnt desc , s.cpu_rate desc

GO
