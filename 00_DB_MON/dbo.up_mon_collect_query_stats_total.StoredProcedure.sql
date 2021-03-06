USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_query_stats_total]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[up_mon_collect_query_stats_total]
AS
set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   

exec up_switch_partition @table_name = 'DB_MON_QUERY_STATS_TOTAL', @column_name = 'REG_DATE'   

declare @reg_date datetime
  
set @reg_date = GETDATE()  
  
insert dbo.DB_MON_QUERY_STATS_TOTAL (
	reg_date, sql_handle, db_id, object_id, creation_time, distinct_count, count, execution_count, 
	worker_time, physical_reads, logical_reads, logical_writes, elapsed_time)
select @reg_date, qs.sql_handle, qt.dbid, qt.objectid, creation_time,  
 distinct_cnt, count, execution_count, 
 worker_time, physical_reads, logical_reads, logical_writes, elapsed_time  
from (      
 select  
   sql_handle      
   , max(creation_time) as creation_time      
   , count(distinct statement_start_offset) as distinct_cnt      
   , max(execution_count) as count      
   , sum(execution_count)     as  execution_count            
   , sum(total_worker_time)     as  worker_time            
   , sum(total_physical_reads)    as  physical_reads            
   , sum(total_logical_writes)    as  logical_writes            
   , sum(total_logical_reads)    as  logical_reads            
   , sum(total_elapsed_time)    as  elapsed_time         
 from sys.dm_exec_query_stats       
 where convert(varbinary, left(sql_handle, 1)) = 0x03
 group by sql_handle      
 ) qs       
 cross apply sys.dm_exec_sql_text (qs.sql_handle) as qt




GO
