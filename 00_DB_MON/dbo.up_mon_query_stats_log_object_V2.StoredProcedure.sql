USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_log_object_V2]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[up_mon_query_stats_log_object_V2]
@base_date datetime = '',
@object_name varchar(255),
@line_start int,
@line_end int,
@set_option int,
@rowcount int = 10
as
BEGIN
SET NOCOUNT ON

DECLARE @now_date datetime, @day_date datetime, @week_date datetime

IF @base_date = ''
BEGIN
	SET @base_date = GETDATE()
END

SET @now_date = @base_date
SET @day_date = DATEADD(dd, -1, @base_date)
SET @week_date = DATEADD(dd, -7, @base_date)

SELECT @now_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @now_date

SELECT @day_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @day_date

SELECT @week_date=MAX(reg_date) from DB_MON_QUERY_STATS_V3 (nolock)
WHERE reg_date <= @week_date

SELECT @object_name as [object_name], @now_date as base_date,dateadd(mi,-61,@now_date) as to_date--, dateadd(mi,61,@now_date) as from_date

--Now
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@now_date) and s.reg_date <= @now_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc 

--Day
SELECT @object_name as [object_name], @day_date as base_date,dateadd(mi,-61,@day_date) as to_date--, dateadd(mi,61,@day_date) as from_date
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@day_date) and s.reg_date <= @day_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc 


--Week
SELECT @object_name as [object_name], @week_date as base_date,dateadd(mi,-61,@week_date) as to_date--, dateadd(mi,61,@week_date) as from_date
SELECT distinct TOP (@rowcount) 
s.reg_date as reg_date, s.db_name as [db_name]
,cnt_min  as cnt_min   
,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min    
,reads_min, cpu_cnt as cpu_cnt, reads_cnt as reads_cnt, duration_cnt as duration_cnt
--,S.statement_start as statement_start, S.statement_end as statement_end
,S.set_options as set_option
,p.line_start, p.line_end as line_end
FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
left join  dbo.db_mon_query_plan_v3 p (nolock)      
on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
WHERE s.reg_date >= dateadd(mi,-61,@week_date) and s.reg_date <= @week_date
and s.object_name= @object_name and P.line_start= @line_start and p.line_end = @line_end and s.set_options = @set_option
order by reg_date desc
END



GO
