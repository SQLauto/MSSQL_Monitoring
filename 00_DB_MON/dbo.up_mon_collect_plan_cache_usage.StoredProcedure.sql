USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_plan_cache_usage]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_plan_cache_usage
* 작성정보    : 2013-12-20 by seo eun mi
* 관련페이지  : Plan Cache 사용 현황
* 내용        : plan_cache size/count
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_plan_cache_usage] 	
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime, @new_proc_cnt int
/* BODY */

set @reg_date = getdate()

--신규 procedure cache 생성갯수 카운팅
select @new_proc_cnt = count(*)
from sys.dm_exec_query_stats with(nolock)
where creation_time>dateadd(minute, -10, @reg_date)
and convert(varbinary, left(sql_handle, 1)) = 0x03 


INSERT DBMON_PLAN_CACHE
select 
           @reg_date,
		   cacheobjtype, 
           objtype,		    
           count(*) count,
           SUM(refcounts) refcount,
           SUM(cast(usecounts as bigint)) usecount,
           AVG(cast(usecounts as bigint)) usecount_avg,
           cast(SUM(cast(size_in_bytes as bigint)) * 1.0 / 1024 / 1024 as numeric(10,1)) size_in_mb, 
		   CASE WHEN objtype = 'PROC' THEN @new_proc_cnt ELSE count(*) END
from 
           sys.dm_exec_cached_plans with(nolock)
group by 
           cacheobjtype, objtype
order by 
           cacheobjtype, objtype


GO
