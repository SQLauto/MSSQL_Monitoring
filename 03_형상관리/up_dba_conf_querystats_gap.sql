SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO


/*************************************************************************  
* 프로시저명  : dbo.up_dba_conf_querystats_gap
* 작성정보    : 2011-01-25 choi bo ra
* 관련페이지  : 
* 내용        : 
* 수정정보    :
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_conf_querystats_gap 
    @site   char(1),
    @server_id nvarchar(50) = 'A',
    @reg_date datetime, 
    @gap    int = 10
    
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */

if @reg_date is null
    SELECT  top 1  @reg_date = reg_date FROM query_stats_gap with (nolock) order by reg_date desc
else SELECT  top 1  @reg_date = reg_date FROM query_stats_gap with (nolock) where reg_date <= @reg_date order by reg_date desc

--select @server_id

IF @server_id != 'A'
BEGIN
    SELECT  M.server_id, dbo.get_svrnm(M.server_id) as server_name,M.reg_date, M.collect_date, M.gubun,M.rank, M.rank_10, M.rank_week,
            M.db_name, M.object_name, M.statement_start, M.statement_end, M.set_options, M.plan_handle,
            M.cpu_min,M.cnt_min
            
    FROM query_stats_gap AS M with (nolock)  
     JOIN
       (select server_id, MAX(collect_date) as collect_date from query_stats_gap with (nolock)
      where reg_date = @reg_date
      group by server_id ) AS S ON  M.server_id =S.server_id and M.collect_date = S.collect_date
     JOIN serverinfo as i with (nolock) on M.server_id = I.server_id
     JOIN dbo.fn_StringSingleTable(@server_id, ',') as F ON I.server_name = F.value
    WHERE M.reg_date = @reg_date and M.db_name not in ('dbmon','master', 'dbadmin','dba')
         and I.site_gn = @site and  ( (rank_10- rank) > @gap or  (rank_week- rank) > @gap)
    ORDER BY server_id, gubun, rank
END
ELSE
BEGIN
   
     SELECT  M.server_id, dbo.get_svrnm(M.server_id) as server_name,M.reg_date, M.collect_date, M.gubun,M.rank
            ,M.rank_10, M.rank_week
            ,M.db_name, M.object_name, M.statement_start, M.statement_end, M.set_options, M.plan_handle
            ,M.cpu_min,M.cnt_min
    FROM query_stats_gap AS M with (nolock)  
     JOIN
       (select server_id, MAX(collect_date) as collect_date from query_stats_gap with (nolock)
        where reg_date = @reg_date
        group by server_id ) AS S ON  M.server_id =S.server_id and M.collect_date = S.collect_date
     JOIN serverinfo as i with (nolock) on M.server_id = I.server_id
    WHERE M.reg_date = @reg_date 
         and M.db_name not in ('dbmon','master', 'dbadmin','dba')
         and I.site_gn = @site 
         and ( (rank_10- rank) > @gap or  (rank_week- rank) > @gap)
    ORDER BY server_id, gubun, rank
END


RETURN
Go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
