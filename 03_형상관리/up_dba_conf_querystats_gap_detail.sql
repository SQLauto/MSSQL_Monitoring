SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_conf_querystats_gap_detail
* 작성정보    : 2011-01-25 choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_conf_querystats_gap_detail
    @server_id      int,
    @reg_date        datetime,
    @db_name        sysname,
    @object_name    sysname,
    @gubun          nvarchar(5),
    @statement_start int,
    @statement_end   int,
    @set_options     int
    
    
    
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @day_date_fr datetime, @day_date_to datetime, @week_date_fr datetime , @week_date_to datetime
    

--select  top 1 @reg_date = reg_date FROM query_stats_gap with (nolock)   order by reg_date desc

set @day_date_fr = dateadd(d, -1, @reg_date)
--convert(datetime,CONVERT(nvarchar(10),dateadd(d, -1, @reg_date), 121 ))
set @day_date_to = @reg_date
--convert(datetime,CONVERT(nvarchar(10),@reg_date, 121))
--set @week_date_fr = convert(datetime,CONVERT(nvarchar(10),dateadd(d, -8, @reg_date), 121 ))
set @week_date_to =dateadd(d, -7, @reg_date)
-- convert(datetime,CONVERT(nvarchar(10),dateadd(d, -7, @reg_date), 121 ))

select @reg_date, @day_date_fr as day_fr,@day_date_to as day_to, @week_date_fr,@week_date_to

/* BODY */
SELECT server_id, convert(nvarchar(16),collect_date, 121) as collect_date
    , CASE WHEN collect_date >= dateadd(mi,-20,@day_date_to) and collect_date < dateadd(mi,20,@day_date_to)  then '금일'
           WHEN collect_date >= dateadd(mi,-20,@day_date_fr) and collect_date < dateadd(mi,20,@day_date_fr) THEN '전일'
       WHEN collect_date >= dateadd(mi,-30,@week_date_to) and collect_date < dateadd(mi,20,@week_date_to) then '전주' 
           ELSE '0' END as type
    --,convert(nvarchar(10),collect_date, 121) as type
    , CASE when server_id = 1003 then 
            convert(nvarchar(2),DATEPART(HH,collect_date)) + ':'+ substring( convert(nvarchar(16),collect_date, 121), 15,2)
            else convert(nvarchar(2),DATEPART(HH,collect_date)) 
                    + ':'+ substring( convert(nvarchar(16),collect_date, 121), 15,1) + '0'
      END as hour
    , db_name, object_name
    ,cnt_min,cpu_min,reads_min,duration_min, cpu_cnt,reads_cnt,duration_cnt
    --,statement_start,statement_end,set_options,master.dbo.fn_varbintohexstr(plan_handle) as plan_handle, create_date,
    ,'exec dbmon.dbo.up_mon_query_plan_info @plan_handle = ' + master.dbo.fn_varbintohexstr(plan_handle)
    + ', @create_date = ''' + CONVERT(nvarchar(24),create_date, 121) + ''', @statement_start =' + CONVERT(nvarchar(10),statement_start)
    + ',@statement_end = ' + CONVERT(nvarchar(10),statement_end)  as query
FROM query_stats_gap with (nolock)
WHERE server_id = @server_id and reg_date = @reg_date and DB_NAME = @db_name and OBJECT_NAME = @object_name 
     and gubun = @gubun
    and statement_start = @statement_start and statement_end = @statement_end and set_options = @set_options
ORDER BY collect_date desc

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO