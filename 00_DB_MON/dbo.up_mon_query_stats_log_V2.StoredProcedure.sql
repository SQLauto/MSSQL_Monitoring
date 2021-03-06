USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_log_V2]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[up_mon_query_stats_log_V2]
@base_date datetime = '',
@type char(3) = 'CPU',
@diff_order varchar(4) = 'DAY'
AS
BEGIN

SET NOCOUNT ON

DECLARE @now_date datetime, @day_date datetime, @week_date datetime
DECLARE @order1 varchar(20), @order2 varchar(20)

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

SELECT	@now_date as now_date, @day_date as day_date, @week_date as week_date, @type as [정렬형식1], @diff_order as [정렬형식2]

SET @order1 = 'diff_day_cpu_min'
SET @order2 = 'diff_week_cpu_min'

IF @type = 'CPU'
BEGIN
SELECT top 10 now_db_name as db, now_object_name
		,now_line_start as line_start , now_line_end as line_end
       --,now_cpu_rate, day_cpu_rate
		,isnull(now_cnt_min,0) as now_cnt, /*day_cnt_min ,*/ isnull(isnull(now_cnt_min,0) - day_cnt_min,0) as diff_day_cnt, isnull(isnull(now_cnt_min,0) - week_cnt_min,0) as diff_week_cnt
		,isnull(now_cpu_min,0) as now_cpu, /*day_cpu_min,*/ isnull(isnull(now_cpu_min,0) - day_cpu_min,0) as diff_day_cpu, isnull(isnull(now_cpu_min,0) - week_cpu_min,0) as diff_week_cpu
		--,isnull(now_duration_min,0) as now_duration_min, /*day_duration_min,*/  isnull(isnull(now_duration_min,0) - isnull(day_duration_min,0),0) as diff_day_duration_min, isnull(isnull(now_duration_min,0) - isnull(week_duration_min,0),0) as diff_week_duration_min
		--,isnull(now_reads_min,0) as now_reads_min, /*day_reads_min ,*/ isnull(isnull(now_reads_min,0) - isnull(day_reads_min,0),0) as diff_day_reads_min, isnull(isnull(now_reads_min,0) - isnull(week_reads_min,0),0) as diff_week_reads_min
		,isnull(now_cpu_cnt,0) as now_cpu_cnt, /*day_cpu_cnt,*/ isnull(isnull(now_cpu_cnt,0) - day_cpu_cnt,0) as diff_day_cpu_cnt , isnull(isnull(now_cpu_cnt,0) - week_cpu_cnt,0) as diff_week_cpu_cnt
		--,isnull(now_duration_cnt,0) as now_duration_cnt, /*day_duration_cnt,*/ isnull(isnull(now_duration_cnt,0) - isnull(day_duration_cnt,0),0) as diff_day_duration_cnt, isnull(isnull(now_duration_cnt,0) - isnull(week_duration_cnt,0),0) as diff_week_duration_cnt
		--,isnull(now_reads_cnt,0) as now_reads_cnt, /*day_reads_cnt ,*/ isnull(isnull(now_reads_cnt,0) - isnull(day_reads_cnt,0),0) as diff_day_reads_cnt , isnull(isnull(now_reads_cnt,0) - isnull(week_reads_cnt,0),0) as diff_week_reads_cnt 
		, CAST(replace(now_set_option,' ','') as VARCHAR)+' | '+CAST(replace(day_set_option,' ','') as VARCHAR)+' | '+ CAST(replace(week_set_option,' ','') as VARCHAR) as set_option
		, 'exec up_mon_query_stats_log_object_V2 ''' + convert(varchar(16),dateadd(mi,1,@now_date),121) + ''',''' + now_object_name + ''',' + CAST(now_line_start as varchar) + ',' + CAST(now_line_end as varchar) + ',' + CAST(now_set_option as varchar) + ',10' as object_detail
    FROM
    (
		SELECT  distinct s.reg_date as now_reg_date, s.db_name as now_db_name, s.object_name as now_object_name, cpu_rate as now_cpu_rate, cnt_min  as now_cnt_min   
                ,(cpu_min /1000) as now_cpu_min,  (duration_min/1000) as now_duration_min    
                ,reads_min as now_reads_min, cpu_cnt as now_cpu_cnt, reads_cnt as now_reads_cnt, duration_cnt as now_duration_cnt
                ,p.line_start as now_line_start, p.line_end as now_line_end
                ,S.statement_start as now_statement_start, S.statement_end as now_statement_end, S.set_options as now_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
        WHERE s.reg_date = @now_date
	) A
	LEFT JOIN
	(     
		SELECT distinct  s.reg_date as day_reg_date, s.db_name as day_db_name, s.object_name as day_object_name, cpu_rate as day_cpu_rate, cnt_min  as day_cnt_min   
                ,(cpu_min /1000) as day_cpu_min,  (duration_min/1000) as day_duration_min    
                ,reads_min as day_reads_min, cpu_cnt as day_cpu_cnt, reads_cnt as day_reads_cnt, duration_cnt as day_duration_cnt
                ,p.line_start as day_line_start, p.line_end as day_line_end
                ,S.statement_start as day_statement_start, S.statement_end as day_statement_end, S.set_options as day_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date
        WHERE s.reg_date = @day_date
    ) B ON  now_object_name = day_object_name and now_statement_start=day_statement_start and now_statement_end=day_statement_end and now_set_option = day_set_option
    LEFT JOIN
	(     
		SELECT distinct  s.reg_date as week_reg_date, s.db_name as week_db_name, s.object_name as week_object_name, cpu_rate as week_cpu_rate, cnt_min  as week_cnt_min   
                ,(cpu_min /1000) as week_cpu_min,  (duration_min/1000) as week_duration_min    
                ,reads_min as week_reads_min, cpu_cnt as week_cpu_cnt, reads_cnt as week_reads_cnt, duration_cnt as week_duration_cnt
                ,p.line_start as week_line_start, p.line_end as week_line_end
                ,S.statement_start as week_statement_start, S.statement_end as week_statement_end, S.set_options as week_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @week_date
    ) C ON  now_object_name = week_object_name and now_statement_start=week_statement_start and now_statement_end=week_statement_end and now_set_option = week_set_option
    WHERE now_db_name not in ('master','msdb','tempdb','model','distribution','dbmon','dbadmin')
    /*and CASE 
		WHEN @diff_order = 'DAY' THEN day_cnt_min 
		WHEN @diff_order = 'WEEK' THEN week_cnt_min
		END is not null*/
    ORDER BY CASE 
		WHEN @diff_order='DAY' THEN now_cpu_min - day_cpu_min
		WHEN @diff_order='WEEK' THEN  now_cpu_min - week_cpu_min
		END DESC
END
ELSE
BEGIN
	SELECT top 10 now_db_name as db, now_object_name
		,now_line_start as line_start , now_line_end as line_end
       --,now_cpu_rate, day_cpu_rate
		,isnull(now_cnt_min,0) as now_cnt, /*day_cnt_min ,*/ isnull(isnull(now_cnt_min,0) - day_cnt_min,0) as diff_day_cnt, isnull(isnull(now_cnt_min,0) - week_cnt_min,0) as diff_week_cnt
		,isnull(now_cpu_min,0) as now_cpu, /*day_cpu_min,*/ isnull(isnull(now_cpu_min,0) - day_cpu_min,0) as diff_day_cpu, isnull(isnull(now_cpu_min,0) - week_cpu_min,0) as diff_week_cpu
		--,isnull(now_duration_min,0) as now_duration_min, /*day_duration_min,*/  isnull(isnull(now_duration_min,0) - isnull(day_duration_min,0),0) as diff_day_duration_min, isnull(isnull(now_duration_min,0) - isnull(week_duration_min,0),0) as diff_week_duration_min
		--,isnull(now_reads_min,0) as now_reads_min, /*day_reads_min ,*/ isnull(isnull(now_reads_min,0) - isnull(day_reads_min,0),0) as diff_day_reads_min, isnull(isnull(now_reads_min,0) - isnull(week_reads_min,0),0) as diff_week_reads_min
		,isnull(now_cpu_cnt,0) as now_cpu_cnt, /*day_cpu_cnt,*/ isnull(isnull(now_cpu_cnt,0) - day_cpu_cnt,0) as diff_day_cpu_cnt , isnull(isnull(now_cpu_cnt,0) - week_cpu_cnt,0) as diff_week_cpu_cnt
		--,isnull(now_duration_cnt,0) as now_duration_cnt, /*day_duration_cnt,*/ isnull(isnull(now_duration_cnt,0) - isnull(day_duration_cnt,0),0) as diff_day_duration_cnt, isnull(isnull(now_duration_cnt,0) - isnull(week_duration_cnt,0),0) as diff_week_duration_cnt
		--,isnull(now_reads_cnt,0) as now_reads_cnt, /*day_reads_cnt ,*/ isnull(isnull(now_reads_cnt,0) - isnull(day_reads_cnt,0),0) as diff_day_reads_cnt , isnull(isnull(now_reads_cnt,0) - isnull(week_reads_cnt,0),0) as diff_week_reads_cnt
		, CAST(replace(now_set_option,' ','') as VARCHAR)+' | '+CAST(replace(day_set_option,' ','') as VARCHAR)+' | '+ CAST(replace(week_set_option,' ','') as VARCHAR) as set_option
		, 'exec up_mon_query_stats_log_object_V2 ''' + convert(varchar(16),dateadd(mi,1,@now_date),121) + ''',''' + now_object_name + ''',' + CAST(now_line_start as varchar) + ',' + CAST(now_line_end as varchar) + ',' + CAST(now_set_option as varchar) + ',10' as object_detail
    FROM
    (
		SELECT distinct  s.reg_date as now_reg_date, s.db_name as now_db_name, s.object_name as now_object_name, cpu_rate as now_cpu_rate, cnt_min  as now_cnt_min   
                ,(cpu_min /1000) as now_cpu_min,  (duration_min/1000) as now_duration_min    
                ,reads_min as now_reads_min, cpu_cnt as now_cpu_cnt, reads_cnt as now_reads_cnt, duration_cnt as now_duration_cnt
                ,p.line_start as now_line_start, p.line_end as now_line_end
                ,S.statement_start as now_statement_start, S.statement_end as now_statement_end, S.set_options as now_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @now_date
	) A
	LEFT JOIN
	(     
		SELECT distinct  s.reg_date as day_reg_date, s.db_name as day_db_name, s.object_name as day_object_name, cpu_rate as day_cpu_rate, cnt_min  as day_cnt_min   
                ,(cpu_min /1000) as day_cpu_min,  (duration_min/1000) as day_duration_min    
                ,reads_min as day_reads_min, cpu_cnt as day_cpu_cnt, reads_cnt as day_reads_cnt, duration_cnt as day_duration_cnt
                ,p.line_start as day_line_start, p.line_end as day_line_end
                ,S.statement_start as day_statement_start, S.statement_end as day_statement_end, S.set_options as day_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @day_date
    ) B ON  now_object_name = day_object_name and now_statement_start=day_statement_start and now_statement_end=day_statement_end and now_set_option = day_set_option
    LEFT JOIN
	(     
		SELECT  distinct s.reg_date as week_reg_date, s.db_name as week_db_name, s.object_name as week_object_name, cpu_rate as week_cpu_rate, cnt_min  as week_cnt_min   
                ,(cpu_min /1000) as week_cpu_min,  (duration_min/1000) as week_duration_min    
                ,reads_min as week_reads_min, cpu_cnt as week_cpu_cnt, reads_cnt as week_reads_cnt, duration_cnt as week_duration_cnt
                ,p.line_start as week_line_start, p.line_end as week_line_end
                ,S.statement_start as week_statement_start, S.statement_end as week_statement_end, S.set_options as week_set_option
        FROM DBMON.dbo.DB_MON_QUERY_STATS_V3 s WITH (NOLOCK)
        left join  dbo.db_mon_query_plan_v3 p (nolock)      
		on s.plan_handle = p.plan_handle and s.statement_start = p.statement_start and s.statement_end = p.statement_end and s.create_date = p.create_date    
        WHERE s.reg_date = @week_date
    ) C ON  now_object_name = week_object_name and now_statement_start=week_statement_start and now_statement_end=week_statement_end and now_set_option = week_set_option
    WHERE now_db_name not in ('master','msdb','tempdb','model','distribution','dbmon','dbadmin')
    /*and CASE 
		WHEN @diff_order = 'DAY' THEN day_cnt_min 
		WHEN @diff_order = 'WEEK' THEN week_cnt_min
		END is not null*/
    ORDER BY CASE 
		WHEN @diff_order='DAY' THEN isnull(isnull(now_cnt_min,0) - day_cnt_min,0)
		WHEN @diff_order='WEEK' THEN  isnull(isnull(now_cnt_min,0) - week_cnt_min,0)
		END DESC
END
END



GO
