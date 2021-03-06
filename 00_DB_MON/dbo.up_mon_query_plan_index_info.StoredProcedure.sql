USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_index_info]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[up_mon_query_plan_index_info]    
 @table_name sysname = NULL,      
 @index_name sysname = NULL      
AS    
set nocount on;    
    
if @table_name is null or @index_name is null   
begin  
 print '@table_name 과 @index_name 에 모두 값이 들어가야 합니다!!!'  
 return  
end;  
    
with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)    
select  db_name, object_name, --plan_handle, --, max(creation_time) as creation_time,    
table_name, index_name -- , query_plan  
from db_mon_query_plan a (nolock)     
OUTER APPLY     
 (    
 SELECT     
   c.value('(./@Index)[1]', 'varchar(128)') AS index_name,    
   c.value('(./@Table)[1]', 'varchar(128)') AS table_name    
 FROM query_plan.nodes('//sql:Object')B(C)    
 )xp    
where (table_name = @table_name or table_name = '[' + @table_name + ']') and (index_name = '[' + @index_name + ']' or index_name = @index_name)  
and creation_time = (select max(creation_time) from db_mon_query_plan (nolock) where db_name = a.db_name and object_name = a.object_name)  
group by db_name, object_name, index_name, table_name  
option (maxdop 1)
GO
