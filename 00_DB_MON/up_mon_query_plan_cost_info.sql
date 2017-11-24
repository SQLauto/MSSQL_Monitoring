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
