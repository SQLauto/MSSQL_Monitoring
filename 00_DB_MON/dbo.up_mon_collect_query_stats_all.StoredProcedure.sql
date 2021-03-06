USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_query_stats_all]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************  
* 프로시저명  : dbo.up_mon_collect_query_stats_all
* 작성정보    : 2010-05-10 by choi bo ra Query Stat 정보 모두 수집 
* 관련페이지  : 
* 내용        : 
* 수정정보    : 
**************************************************************************/
CREATE PROCEDURE [dbo].[up_mon_collect_query_stats_all] 
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @reg_date datetime


/* BODY */
exec UP_SWITCH_PARTITION  @table_name = 'DB_MON_QUERY_STATS_ALL',@column_name = 'reg_date'

set @reg_date =getdate()
INSERT INTO DB_MON_QUERY_STATS_ALL
(reg_date
,rank
,db_name
,scheme_name
,object_name
,query_text
,statement_start_offset
,statement_end_offset
,plan_generation_num
,creation_time
,last_execution_time
,execution_count
,total_worker_time
,last_worker_time
,min_worker_time
,max_worker_time
,total_physical_reads
,last_physical_reads
,min_physical_reads
,max_physical_reads
,total_logical_writes
,last_logical_writes
,min_logical_writes
,max_logical_writes
,total_logical_reads
,last_logical_reads
,min_logical_reads
,max_logical_reads
,total_clr_time
,last_clr_time
,min_clr_time
,max_clr_time
,total_elapsed_time
,last_elapsed_time
,min_elapsed_time
,max_elapsed_time
,sql_handle
,plan_handle)
select 
     @reg_date
    ,row_number() over(order by total_worker_time desc, last_execution_time desc ) as rank
    ,db_name(st.dbid) as db_name
    ,object_schema_name(st.objectid,dbid) as scheme_name
    ,object_name(st.objectid,dbid) as object_name
    , isnull(substring(st.text,qs.statement_start_offset / 2 + 1,                          
					(case when qs.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), st.text)) * 2                               
					else qs.statement_end_offset end - qs.statement_start_offset) / 2), '')
       as query_text
    ,statement_start_offset
    ,statement_end_offset
    ,plan_generation_num
    ,creation_time
    ,last_execution_time
    ,execution_count
    ,total_worker_time
    ,last_worker_time
    ,min_worker_time
    ,max_worker_time
    ,total_physical_reads
    ,last_physical_reads
    ,min_physical_reads
    ,max_physical_reads
    ,total_logical_writes
    ,last_logical_writes
    ,min_logical_writes
    ,max_logical_writes
    ,total_logical_reads
    ,last_logical_reads
    ,min_logical_reads
    ,max_logical_reads
    ,total_clr_time
    ,last_clr_time
    ,min_clr_time
    ,max_clr_time
    ,total_elapsed_time
    ,last_elapsed_time
    ,min_elapsed_time
    ,max_elapsed_time
    ,sql_handle
    ,plan_handle
from sys.dm_exec_query_stats  as qs with (nolock)
     cross apply sys.dm_exec_sql_text(qs.plan_handle) st
--where total_worker_time /1000 > 0


RETURN

GO
