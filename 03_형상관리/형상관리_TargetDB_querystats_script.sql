USE DBMON
GO
/*************************************************************************      
* 프로시저명  : dbo.up_mon_collect_query_stats_gap    
* 작성정보    : 2010-01-26 by choi bo ra    
* 관련페이지  :     
* 내용        : 현재 실해된 qeury의 cpu/cnt의 호출 순위 수집    
* 수정정보    : exec up_mon_collect_query_stats_gap 11, 10, 2    
**************************************************************************/    
CREATE PROCEDURE dbo.up_mon_collect_query_stats_gap    
    @server_id      int    
   ,@top_cnt        int = 20    
   ,@gap            int = 5    
AS    
/* COMMON DECLARE */    
SET NOCOUNT ON    
SET FMTONLY OFF    
/* USER DECLARE */    
declare @from_date datetime, @to_date datetime  , @week_date datetime , @day_date datetime                 
declare @reg_date datetime    
set @reg_date  = convert(nvarchar(15),GETDATE(), 121)  + '0:00'      
    
declare @gubun nvarchar(5), @rank int, @rank_10 int, @rank_week int, @db_name sysname, @object_name sysname    
        ,@statement_start int, @statement_end int,  @set_options int    
    
/* BODY */    
    
select top 1 @to_date = reg_date from DB_MON_QUERY_STATS_V2 with (nolock)  order by reg_date  desc    
select top 1 @from_date = reg_date from DB_MON_QUERY_STATS_V2 with (nolock)      
    where reg_date < @to_date order by reg_date desc    
    
select top 1 @week_date = reg_date from DB_MON_QUERY_STATS_V2 with (nolock)      
    where reg_date <= dateadd(mi,1, dateadd(d, -7, convert(datetime,(convert(nvarchar(17),@to_date, 121) + '00') ))    
    ) order by reg_date desc    
    
select top 1 @day_date = reg_date from DB_MON_QUERY_STATS_V2 with (nolock)      
    where reg_date <= dateadd(mi,1, dateadd(d, -1, convert(datetime,(convert(nvarchar(17),@to_date, 121) + '00') ))    
    ) order by reg_date desc    
    
    
      
--select @to_date as today, @day_date as day_dt, @from_date as from_dt, @week_date as week_dt    
        
DECLARE sp_query_gap CURSOR FOR    
    
SELECT  'CPU' as gubun, T.rank, isnull(F.rank, @top_cnt+10) as day_rank, isnull(W.rank, @top_cnt+10) as week_rank    
    ,  T.db_name, T.object_name     
    --,(F.rank-T.rank) as gap, (W.rank-T.rank) as week_gap    
    , T.statement_start,T.statement_end, T.set_options    
FROM     
( select  top (@top_cnt) row_number() over ( order by cpu_min desc ) rank --, reg_date    
    ,db_name, object_id, object_name    
    ,plan_handle, statement_start,statement_end, set_options, create_date        
from DB_MON_QUERY_STATS_V2 with (nolock)              
where reg_date = @to_date     
order by cpu_min desc ) as T    
LEFT JOIN    
    (select  top (@top_cnt+10) row_number() over ( order by cpu_min desc ) rank --, reg_date    
  ,db_name, object_id, object_name    
  ,plan_handle, statement_start,statement_end, set_options, create_date        
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date = @from_date     
    order by cpu_min desc ) AS F  ON T.db_name = F.db_name and  T.object_name =F.object_name    
         and  T.statement_start = F.statement_start and T.statement_end =F.statement_end and T.set_options =F.set_options    
LEFT JOIN     
 (select top (@top_cnt+10) row_number() over ( order by cpu_min desc ) rank--, reg_date    
  ,db_name, object_id, object_name    
  ,plan_handle, statement_start,statement_end, set_options, create_date    
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date = @week_date     
    order by cpu_min desc ) AS W ON T.db_name = W.db_name and  T.object_name =W.object_name    
         and  T.statement_start = W.statement_start and T.statement_end =W.statement_end and T.set_options =W.set_options    
WHERE (isnull(F.rank,@top_cnt)-T.rank) > @gap OR F.rank is null    
UNION ALL    
SELECT 'CNT' as gubun, T.rank, isnull(F.rank,@top_cnt+10) as day_rank, isnull(W.rank,@top_cnt+10) as week_rank,  T.db_name, T.object_name     
    --,(F.rank-T.rank) as gap, (W.rank-T.rank) as week_gap   
    , T.statement_start,T.statement_end, T.set_options    
FROM     
( select  top (@top_cnt) row_number() over ( order by cnt_min desc ) rank--, reg_date    
    ,db_name, object_id, object_name    
    ,plan_handle, statement_start,statement_end, set_options, create_date        
from DB_MON_QUERY_STATS_V2 with (nolock)              
where reg_date = @to_date     
order by cnt_min desc ) as T    
LEFT JOIN    
    (select  top (@top_cnt+10) row_number() over ( order by cnt_min desc ) rank--, reg_date    
  ,db_name, object_id, object_name    
  ,plan_handle, statement_start,statement_end, set_options, create_date        
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date = @day_date     
    order by cnt_min desc ) AS F  ON T.db_name = F.db_name and  T.object_name =F.object_name    
         and  T.statement_start = F.statement_start and T.statement_end =F.statement_end and T.set_options =F.set_options    
LEFT JOIN     
 (select top (@top_cnt+10) row_number() over ( order by cnt_min desc ) rank--, reg_date    
  ,db_name, object_id, object_name    
  ,plan_handle, statement_start,statement_end, set_options, create_date    
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date = @week_date     
    order by cnt_min desc ) AS W ON T.db_name = W.db_name and  T.object_name =W.object_name    
         and  T.statement_start = W.statement_start and T.statement_end =W.statement_end and T.set_options =W.set_options    
WHERE (isnull(F.rank,@top_cnt+10)-T.rank) > @gap  OR F.rank is null    
ORDER BY gubun, rank    
 
  
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WORK_QUERY_STATS_GAP]') AND type in (N'U'))    
CREATE TABLE WORK_QUERY_STATS_GAP    
    (   server_id int, reg_date datetime, collect_date datetime,    
        gubun nvarchar(5), rank int, rank_10 int, rank_week int, db_name sysname, object_name sysname,    
        cnt_min bigint, cpu_min bigint, reads_min bigint, duration_min bigint,     
        cpu_cnt bigint, reads_cnt bigint, duration_cnt bigint, plan_handle varbinary(64),statement_start int,statement_end int,    
        set_options int,create_date datetime    
     )    
       
TRUNCATE TABLE WORK_QUERY_STATS_GAP       
    
-- 커서 open    
OPEN sp_query_gap     
FETCH NEXT FROM sp_query_gap into  @gubun, @rank, @rank_10, @rank_week, @db_name,@object_name    
        ,@statement_start,@statement_end, @set_options    
WHILE @@fetch_status = 0           
BEGIN      
    -- collect today    
    insert into WORK_QUERY_STATS_GAP    
    select top 3  @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    
    ,cnt_min, cpu_min, reads_min, duration_min    
    ,cpu_cnt,reads_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date >= dateadd(mi, -30, @to_date ) and reg_date <= @to_date      
     and  db_name = @db_name and object_name = @object_name    
     and  statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    
    order by reg_date desc    
        
    -- collect yesterday    
    insert into WORK_QUERY_STATS_GAP    
    select top 3  @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    
    ,cnt_min, cpu_min, reads_min, duration_min    
    ,cpu_cnt,reads_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date >= dateadd(mi, -30, @day_date ) and reg_date <= @day_date     
        and  db_name = @db_name and object_name = @object_name    
        and  statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    
    order by reg_date desc    
        
    -- collect week    
    insert into WORK_QUERY_STATS_GAP    
    select top 3 @server_id, @reg_date , reg_date as collect_date, @gubun , @rank, @rank_10, @rank_week, @db_name, @object_name    
    ,cnt_min, cpu_min, reads_min, duration_min    
    ,cpu_cnt,reads_cnt,duration_cnt ,plan_handle, statement_start,statement_end, set_options, create_date    
    from DB_MON_QUERY_STATS_V2 with (nolock)              
    where reg_date >= dateadd(mi, -30, @week_date ) and reg_date <= @week_date      
        and  db_name = @db_name and object_name = @object_name    
        and  statement_start = @statement_start and statement_end = @statement_end  and set_options = @set_options    
    order by reg_date desc    
    
    
    
    
FETCH NEXT FROM sp_query_gap into  @gubun, @rank, @rank_10, @rank_week, @db_name,@object_name    
        ,@statement_start,@statement_end,@set_options     
END    
    
CLOSE sp_query_gap           
DEALLOCATE sp_query_gap           
  
-- 커서 end    
select * from WORK_QUERY_STATS_GAP    
--drop table WORK_QUERY_STATS_GAP    
    
RETURN 
GO