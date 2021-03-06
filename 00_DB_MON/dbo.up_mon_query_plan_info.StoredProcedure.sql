USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_info]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 2010-08-25 13:32 */
CREATE PROCEDURE [dbo].[up_mon_query_plan_info]
	@plan_handle varbinary(64),
	@statement_start int,
	@statement_end int,
	@create_date datetime
AS
set nocount on

	select db_name, object_name, f.line_start, f.line_end, 
		dbo.fn_getquerytext(plan_handle, statement_start, statement_end) as query, query_plan
	from dbo.db_mon_query_plan_v2 p (nolock) 
		cross apply dbo.fn_getobjectline(p.plan_handle, p.statement_start, p.statement_end) f
	where plan_handle = @plan_handle
	  and statement_start = @statement_start
	  and statement_end = @statement_end
	  and create_date = @create_date
	  
	exec up_mon_query_plan_scan_info @plan_handle = @plan_handle, @statement_start = @statement_start, @statement_end = @statement_end, @create_date = @create_date
GO
