USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_compile_info]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[up_mon_query_plan_compile_info]
	@object_name sysname = NULL,
	@db_name sysname = NULL
AS

SET NOCOUNT ON;

with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)
SELECT 
 db_name
 , object_name
 , max(creation_time) as creation_time
 , sum([CompileTime(ms)]) as compile_time_ms
 , sum([CachedPlanSize(kb)]) as cached_plan_size_KB
 , sum([CompileCPU(ms)]) as compile_cpu_ms
 , sum([CompileMemory(kb)]) as compile_memory_KB
 FROM
  (
   SELECT 
    db_name
    ,object_name
    ,plan_handle
    ,creation_time
    , cast(query_plan as xml) as query_plan
   FROM DB_MON_QUERY_PLAN AS qs
  )X 
OUTER APPLY 
 (
 SELECT 
  c.value('(./@CompileTime)[1]','INT') AS "CompileTime(ms)"
  ,c.value('(./@CachedPlanSize)[1]','INT') AS "CachedPlanSize(kb)"
  ,c.value('(./@CompileCPU)[1]','INT') AS "CompileCPU(ms)"
  ,c.value('(./@CompileMemory)[1]','INT') AS "CompileMemory(kb)"
 FROM query_plan.nodes('//sql:QueryPlan')B(C)
 )xp
 WHERE (@object_name IS NULL OR object_name = @object_name)
   and (@db_name IS NULL OR db_name = @db_name)
 GROUP BY db_name, object_name, plan_handle
 order by db_name, object_name, creation_time desc


GO
