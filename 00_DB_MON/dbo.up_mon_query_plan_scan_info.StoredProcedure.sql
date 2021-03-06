USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_query_plan_scan_info]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 2010-08-26 09:43 */
CREATE PROCEDURE [dbo].[up_mon_query_plan_scan_info]   
 @plan_handle varbinary(64),
 @statement_start int,
 @statement_end int,
 @create_date datetime,
 @is_lookup int = 0  
AS  
set nocount on ;
  

  
with XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)    
select   
nodeid, table_name, index_name, scanType
from db_mon_query_plan_v2 a (nolock)         
OUTER APPLY         
(        
 SELECT  
  c.value('(./@NodeId)[1]', 'int') as nodeid,  
  c.value('(./@LogicalOp)[1]', 'varchar(128)') AS scanType,  
  isnull(c.value('(./sql:IndexScan/@Lookup)[1]', 'int'), 0) AS is_lookup,  
  c.value('(./sql:IndexScan/sql:Object/@Index)[1]', 'varchar(128)') AS index_name,        
  c.value('(./sql:IndexScan/sql:Object/@Table)[1]', 'varchar(128)') AS table_name  
/*  ,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:StartRange/@ScanType)[1]', 'varchar(128)') as startkey,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:StartRange/sql:RangeColumns/sql:ColumnReference/@Column)[1]', 'varchar(128)') as col1,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:EndRange/@ScanType)[1]', 'varchar(128)') as endkey,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:EndRange/sql:RangeColumns/sql:ColumnReference/@Column)[1]', 'varchar(128)') as col2,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:Prefix/@ScanType)[1]', 'varchar(128)') as prefix,  
  c.value('(./sql:IndexScan/sql:SeekPredicates/sql:SeekPredicate/sql:Prefix/sql:RangeColumns/sql:ColumnReference/@Column)[1]', 'varchar(128)') as col3*/  
 FROM query_plan.nodes('//sql:RelOp')B(C)  
 WHERE c.value('(./@LogicalOp)[1]', 'varchar(128)') LIKE '%Index%'  
) xp  
where a.plan_handle = @plan_handle and a.statement_start = @statement_start and a.statement_end = @statement_end and a.create_date = @create_date
and (@is_lookup = 1 or is_lookup = @is_lookup)  
option (maxdop 1);  
  
  
  
GO
