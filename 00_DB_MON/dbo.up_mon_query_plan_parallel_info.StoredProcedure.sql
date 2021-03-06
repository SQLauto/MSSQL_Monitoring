
CREATE PROCEDURE up_mon_query_plan_cost_info
 @object_name sysname = NULL,  
 @db_name sysname = NULL  
AS
set nocount on;

with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)
select  object_name, plan_handle, max(create_date) as create_date,
sum(convert(money, Query_Cost)) as query_cost
from db_mon_query_plan_v3 (nolock) 
OUTER APPLY 
 (
 SELECT 
   c.value('(./@NodeId)[1]', 'int') AS NodeId,
   c.value('(./@EstimatedTotalSubtreeCost)[1]', 'real') AS Query_Cost
 FROM query_plan.nodes('//sql:RelOp')B(C)
 )xp
where NodeId = 0 
   and (@object_name IS NULL OR object_name = @object_name)  
   and (@db_name IS NULL OR db_name = @db_name) 
group by object_name, plan_handle
order by object_name, max(create_date) desc
go


ALTER PROCEDURE up_mon_query_plan_parallel_info
AS
SET NOCOUNT ON;

select qp.db_name, qp.object_name, qp.sql_handle, qp.plan_handle, qp.create_date
into #TEMP_LAST_OBJ
from DB_MON_QUERY_PLAN_V3 qp (nolock) 
	join (select sql_handle, max(create_date) as create_date from DB_MON_QUERY_PLAN_V3 GROUP BY sql_handle) as lst
	ON qp.sql_handle = lst.sql_handle and qp.create_date = lst.create_date;


with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)
SELECT 
 db_name
 , object_name
 , sql_handle
 , plan_handle
 , max(create_date) as create_datecreate_date
 , sum(case when physicalOp = 'Parallelism' then 1 else 0 end) as is_parallel
 INTO #TEMP_PARALLEL_OBJ
 FROM
  (
   SELECT 
    db_name
    ,object_name
    ,sql_handle
    ,plan_handle
    ,create_date
    , cast(query_plan as xml) as query_plan
   FROM DB_MON_QUERY_PLAN_V3 AS qs (nolock)
  )X 
OUTER APPLY 
 (
 SELECT 
  c.value('(./@PhysicalOp)[1]','varchar(100)') AS PhysicalOp
 FROM query_plan.nodes('//sql:RelOp')B(C)
 )xp
-- WHERE PhysicalOp = 'Parallelism'
 GROUP BY db_name, object_name, sql_handle, plan_handle
 
--select * from #TEMP_LAST_OBJ
 
--select * FROM #TEMP_PARALLEL_OBJ

select last.db_name as db_name, 
	last.object_name as object_name,
	max(last.creation_time) as last_plan_creation_time,
	max(parall.creation_time) as parall_plan_creation_time,
	max(serial.creation_time) as serial_plan_creation_time,
	case when max(last.creation_time) = max(parall.creation_time) then	
			case when max(last.creation_time) > max(serial.creation_time) then 'SERAIL -> PARALLEL'
				 else 'PARALLEL' end 
		 when max(last.create_date) > max(parall.create_date) then 'PARALLEL -> SERIAL'
		 else null
	end as is_parallel
from #TEMP_LAST_OBJ last 
	LEFT OUTER JOIN #TEMP_PARALLEL_OBJ PARALL
		on last.db_name = parall.db_name and last.object_name = parall.object_name and parall.is_parallel > 0
	left outer join #TEMP_PARALLEL_OBJ SERIAL
		on last.db_name = serial.db_name and last.object_name = serial.object_name and serial.is_parallel = 0
--group by isnull(last.sql_handle, parall.sql_handle)
where (parall.create_date IS NOT NULL)
group by last.db_name, last.object_name

drop table #TEMP_LAST_OBJ
drop table #TEMP_PARALLEL_OBJ
