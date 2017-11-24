SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'up_DBA_syscache_exec_stats' 
	   AND 	  type = 'P')
    DROP PROCEDURE  up_DBA_syscache_exec_stats
*/

/*************************************************************************  
* 프로시저명  : dbo.up_DBA_syscache_exec_stats 
* 작성정보    : 2007-10-31 by choi bo ra
* 관련페이지  :  
* 내용        : TIGER DB의 캐시 사용 방법에 대한 정보를 포함합니다. 

* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_DBA_syscache_exec_stats 
	@dbname		SYSNAME
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @dt_getdate     NVARCHAR(10)
SET @dt_getdate = convert(nvarchar(10), getdate(), 120) 

/* BODY */
INSERT DBA.dbo.SYSCACHE_EXEC_STATS
(
    reg_dt              ,
    objid               ,
    objname             ,
    usecounts           ,
    execution_count     ,
    plan_generation_num ,
    total_elapsed_time  ,
    avg_elapsed_time    ,
    total_worker_time   ,
    avg_worker_time     ,
    total_logical_reads ,
    total_logical_writes,
    total_physical_reads,
    avg_logical_reads   ,
    avg_logical_writes  ,
    avg_physical_reads  ,
    cacheobjtype        ,
    objtype             ,
    bucketid            ,
    dbname              ,
    setopts             ,
    plan_handle         ,
    sql_handle          
 )
SELECT TOP 300 @dt_getdate AS reg_dt, est.objectid, object_name(est.objectid) AS objname, ecp.usecounts, 
		eqs.execution_count, eqs.plan_generation_num, eqs.total_elapsed_time, 
		(eqs.total_elapsed_time/ eqs.execution_count) AS avg_elapsed_time,
		eqs.total_worker_time, (eqs.total_worker_time/execution_count) AS avg_worker_time,
		eqs.total_logical_reads, eqs.total_logical_writes,total_physical_reads,
		(eqs.total_logical_reads /eqs.execution_count) AS avg_logical_reads, 
		(eqs.total_logical_writes/eqs.execution_count) AS avg_logical_writes,
		(total_physical_reads /eqs.execution_count) AS avg_physical_reads,
		ecp.cacheobjtype, ecp.objtype, ecp.bucketid, db_name(est.dbid) as dbname, CONVERT(INT, epa.value) AS setopts, 
		ecp.plan_handle, eqs.sql_handle
FROM sys.dm_exec_cached_plans AS ecp
	INNER JOIN (SELECT plan_handle, sql_handle, sum(plan_generation_num) AS plan_generation_num,
						SUM(execution_count) AS execution_count, SUM(total_worker_time/1000.00) AS total_worker_time,
						SUM(total_elapsed_time /1000.00) AS total_elapsed_time,
						SUM(total_logical_reads) AS total_logical_reads, SUM(total_physical_reads) AS total_physical_reads,
						SUM(total_logical_writes) AS total_logical_writes
				 FROM sys.dm_exec_query_stats
			     GROUP BY plan_handle, sql_handle) AS eqs ON ecp.plan_handle = eqs.plan_handle
	OUTER APPLY sys.dm_exec_sql_text(ecp.plan_handle) AS est
	CROSS APPLY sys.dm_exec_plan_attributes(ecp.plan_handle) AS epa
WHERE est.dbid = DB_ID(@dbname) AND epa.attribute = 'set_options'
ORDER BY usecounts desc 
 

IF @@ERROR <> 0 RETURN

RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO