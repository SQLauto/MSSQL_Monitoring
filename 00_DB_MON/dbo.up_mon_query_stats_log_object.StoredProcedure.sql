USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_stats_log_object]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************  
* 프로시저명  : dbo.up_mon_query_stats_log_object
* 작성정보    : 2010-07-12 by choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    : exec dbo.up_mon_query_stats_log_object '2010-07-13 11:00', '2010-07-13 14:22'
        , 'UPAR_Sell3_SellPlus_SelectSellingItemListByDefaultCondition', 1

**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_query_stats_log_object] 
    @base_from_dt       datetime,
    @base_to_dt         datetime,
    @object_name        sysname,
    @gubun              tinyint = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
DECLARE @from_dt datetime, @to_dt datetime


-- 작업
SELECT @base_from_dt = max(reg_date) 
FROM DBMON.dbo.DB_MON_QUERY_STATS with (nolock)
WHERE reg_date >= @base_from_dt and reg_date < dateadd(mi, 10, @base_from_dt)


SELECT @from_dt =min(reg_date) 
FROM DBMON.dbo.DB_MON_QUERY_STATS with (nolock)
WHERE reg_date >= dateadd(d, -1, @base_from_dt) and reg_date < dateadd(mi, 10,dateadd(d, -1, @base_from_dt))

SELECT '하루전 해당 시간' as gubun, @base_from_dt as base_from_dt, @from_dt as from_dt

	
   SELECT  top 50 base.reg_date as base_dt, diff.reg_date as des_date
           ,base.db_name, base.object_name, base.cpu_rate
           ,base.cnt_min as base_cnt_min, isnull(diff.cnt_min,0) as des_cnt_min , (base.cnt_min - isnull(diff.cnt_min,0)) as diff_cnt_min
           ,base.cpu_min as base_cpu_min, (base.cpu_min - isnull(diff.cpu_min,0)) as diff_cpu_min
           ,base.duration_min as base_duration_min,  (base.duration_min -isnull(diff.duration_min,0)) as diff_duration_min
           ,base.reads_min as base_reads_min, (base.reads_min - isnull(diff.reads_min,0)) as diff_reads_min
           ,base.cpu_cnt as base_cpu_cnt, (base.cpu_cnt - isnull(diff.cpu_cnt,0)) as diff_cpu_cnt
           ,base.duration_cnt as base_duration_cnt, (base.duration_cnt - isnull(diff.duration_cnt,0)) as diff_duration_cnt
           ,base.reads_cnt as base_reads_cnt, (base.reads_cnt - isnull(diff.reads_cnt,0)) as diff_reads_cnt
    FROM
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date=  @base_from_dt
         AND object_name = @object_name ) as base
    LEFT JOIN 
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date = @from_dt 
          AND object_name = @object_name ) as diff   on base.db_name =diff.db_name and base.object_name = diff.object_name
    ORDER BY diff_cpu_min desc


	SELECT @from_dt =min(reg_date) 
	FROM DBMON.dbo.DB_MON_QUERY_STATS with (nolock)
	WHERE reg_date >= dateadd(d, -7, @base_from_dt) and reg_date < dateadd(mi, 10,dateadd(d, -7, @base_from_dt))

    SELECT '일주일 해당 시간' as gubun, @base_from_dt as base_from_dt, @from_dt as from_dt

    -- 일주일 전주 해당 시간 비교
   SELECT  top 50 base.reg_date as base_dt, diff.reg_date as des_date
           ,base.db_name, base.object_name, base.cpu_rate
           ,base.cnt_min as base_cnt_min, isnull(diff.cnt_min,0) as des_cnt_min , (base.cnt_min - isnull(diff.cnt_min,0)) as diff_cnt_min
           ,base.cpu_min as base_cpu_min, (base.cpu_min - isnull(diff.cpu_min,0)) as diff_cpu_min
           ,base.duration_min as base_duration_min,  (base.duration_min -isnull(diff.duration_min,0)) as diff_duration_min
           ,base.reads_min as base_reads_min, (base.reads_min - isnull(diff.reads_min,0)) as diff_reads_min
           ,base.cpu_cnt as base_cpu_cnt, (base.cpu_cnt - isnull(diff.cpu_cnt,0)) as diff_cpu_cnt
           ,base.duration_cnt as base_duration_cnt, (base.duration_cnt - isnull(diff.duration_cnt,0)) as diff_duration_cnt
           ,base.reads_cnt as base_reads_cnt, (base.reads_cnt - isnull(diff.reads_cnt,0)) as diff_reads_cnt
    FROM
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date=  @base_from_dt
         AND object_name = @object_name ) as base
    LEFT JOIN 
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date= @from_dt 
          AND object_name = @object_name ) as diff   on base.db_name =diff.db_name and base.object_name = diff.object_name
    ORDER BY diff_cpu_min desc

   
    -- 앞뒤 20분 차이 비교
    SET @from_dt = dateadd(mi, -21,@base_from_dt )
    SET @to_dt = dateadd(mi, 91, @base_from_dt)
    
    
    select '20분전후' as gubun,  @from_dt as from_dt, @to_dt as to_dt
    SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
    FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
    WHERE reg_date>= @from_dt and reg_date <@to_dt
         AND object_name = @object_name
    ORDER BY reg_date
    
  IF @gubun = 1
  BEGIN
    -- 일주일전 해당 범위
    SET @from_dt = dateadd(d, -7,@base_from_dt )
    SET @to_dt = dateadd(d, -7, @base_to_dt)
    
    SELECT @from_dt = min(reg_date) 
    FROM DBMON.dbo.DB_MON_QUERY_STATS with (nolock)
    WHERE reg_date >= @from_dt and reg_date < @to_dt
    

    SELECT '일주일 전 해당범위' as gubun, @base_from_dt as base_from_dt, @base_to_dt as base_to_dt, @from_dt as from_dt, @to_dt as to_dt
    
     SELECT top 50 base.reg_date as base_dt, diff.reg_date as des_date
           ,base.db_name, base.object_name, base.cpu_rate
           ,base.cnt_min as base_cnt_min, isnull(diff.cnt_min,0) as des_cnt_min , (base.cnt_min - isnull(diff.cnt_min,0)) as diff_cnt_min
           ,base.cpu_min as base_cpu_min, (base.cpu_min - isnull(diff.cpu_min,0)) as diff_cpu_min
           ,base.duration_min as base_duration_min,  (base.duration_min -isnull(diff.duration_min,0)) as diff_duration_min
           ,base.reads_min as base_reads_min, (base.reads_min - isnull(diff.reads_min,0)) as diff_reads_min
           ,base.cpu_cnt as base_cpu_cnt, (base.cpu_cnt - isnull(diff.cpu_cnt,0)) as diff_cpu_cnt
           ,base.duration_cnt as base_duration_cnt, (base.duration_cnt - isnull(diff.duration_cnt,0)) as diff_duration_cnt
           ,base.reads_cnt as base_reads_cnt, (base.reads_cnt - isnull(diff.reads_cnt,0)) as diff_reads_cnt
    FROM
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date>= @base_from_dt  and reg_date <@base_to_dt 
         AND object_name = @object_name) as base
    JOIN 
        (SELECT  reg_date, db_name, object_name, cpu_rate, cnt_min
                ,(cpu_min /1000) as cpu_min,  (duration_min/1000) as duration_min
                ,reads_min, cpu_cnt, reads_cnt, duration_cnt
        FROM DBMON.dbo.DB_MON_QUERY_STATS WITH (NOLOCK)
        WHERE reg_date>= @from_dt and reg_date <@to_dt 
             AND object_name = @object_name) as diff  
               on base.db_name =diff.db_name and base.object_name = diff.object_name  
             and substring(convert(nvarchar(16), base.reg_date, 121), 12, 2) = substring(convert(nvarchar(16), diff.reg_date, 121), 12, 2)
             and convert(int, substring(convert(nvarchar(16), base.reg_date, 121), 15, 2) ) /10 
                    =convert(int, substring(convert(nvarchar(16), diff.reg_date, 121), 15, 2) ) /10
    ORDER BY base.reg_date, (base.cpu_min - isnull(diff.cpu_min,0)) desc
  END


RETURN
GO
