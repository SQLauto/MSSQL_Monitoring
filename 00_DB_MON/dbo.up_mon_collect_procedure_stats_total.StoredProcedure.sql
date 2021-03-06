USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_collect_procedure_stats_total]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




    
CREATE PROCEDURE [dbo].[up_mon_collect_procedure_stats_total]    
AS    
set nocount on    
    
exec up_switch_partition @table_name = 'DB_MON_PROCEDURE_STATS_TOTAL', @column_name = 'REG_DATE'       
    
declare @reg_date datetime    
  
declare @procedure_stats table (  
 db_id int not null,   
 object_id int not null,   
 sql_handle varbinary(64),   
 cached_time datetime not null,  
 plan_handle varbinary(64),   
 execution_count bigint,  
 worker_time bigint,  
 physical_reads bigint,  
 logical_reads bigint,  
 logical_writes bigint,  
 elapsed_time bigint  
)  
    
set @reg_date = GETDATE()    
  
insert @procedure_stats (    
 db_id, object_id, sql_handle, plan_handle, cached_time,    
 execution_count, worker_time, physical_reads, logical_reads, logical_writes, elapsed_time )    
select     
 database_id,    
 object_id,    
 sql_handle,    
 plan_handle,    
 cached_time,    
 execution_count,    
 total_worker_time,    
 total_physical_reads,    
 total_logical_reads,    
 total_logical_writes,    
 total_elapsed_time    
from sys.dm_exec_procedure_stats with (nolock)  
where database_id<>32767  
  
insert dbo.DB_MON_PROCEDURE_STATS_TOTAL (    
 reg_date, db_id, object_id, sql_handle, plan_handle, cached_time,    
 execution_count, worker_time, physical_reads, logical_reads, logical_writes, elapsed_time )    
select getdate(),   
 db_id,    
 object_id,    
 sql_handle,    
 plan_handle,    
 cached_time,    
 execution_count,    
 worker_time,    
 physical_reads,    
 logical_reads,    
 logical_writes,    
 elapsed_time    
from @procedure_stats a  
where cached_time = (select top 1 cached_time from @procedure_stats where db_id = a.db_id and object_id = a.object_id and sql_handle = a.sql_handle order by cached_time desc)  

GO
