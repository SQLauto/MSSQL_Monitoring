/*************************************************************************        
* 프로시저명  : dbo.up_dba_select_table_size 1,1       
* 작성정보    : 2010-03-23 by choi bo ra      
* 관련페이지  :      up_dba_select_table_size   
* 내용        : server별 DB별 table size 측정      
* 수정정보    : KB를 MB로 수정 (노상국)  
							  2015-01-20 by choi bo ra 테이블 확장 속성 2건 생성, 중복 row 제거    
**************************************************************************/      
ALTER PROCEDURE up_dba_select_table_size
    @server_id          int,      
    @instance_id        int      
AS      
/* COMMON DECLARE */      
SET NOCOUNT ON      
SET FMTONLY OFF      
      
  
/* USER DECLARE */      
DECLARE @str_sql        nvarchar(4000)      
DECLARE @str_sql1        nvarchar(4000)      
DECLARE @dbname     varchar(50)       
DECLARE @dbid       nvarchar(50)        
      
CREATE TABLE  #temp_table       
(      
    seq_no      int identity(1,1),      
    server_id   smallint,      
    instance_id smallint,      
    rank        int,      
    db_id        int,      
    db_name                   nvarchar(128),      
    object_id   int,      
    schema_name nvarchar(128),      
    table_name  nvarchar(128),      
    row_count   bigint,      
    reserved     bigint,      
    data         bigint,      
    index_size   bigint,      
    unused       bigint,      
    reg_dt      datetime,     
 logical_name varchar(256),  
 ext_prop  nvarchar(512)  
)      

CREATE TABLE #TEMP_TABLE2  
(  
SEQ INT IDENTITY(1,1),  
DB_NAME NVARCHAR(128)  
)  

      
/* BODY */      

set @str_sql1 = N'      
    SELECT ' + convert(nvarchar(20), @server_id) + ' as server_id , ' + convert(nvarchar(20), @instance_id) + ' as instance_id,      
        (row_number() over(order by (a1.reserved) desc)) as rank,      
        db_id() as db_id,      
        db_name() as db_name,      
        a2.object_id ,      
                            a3.name AS schema_name,      
                            a2.name AS table_name,      
                            a1.rows as row_count,      
                            a1.reserved * 8/1024 AS reserved,      
                            a1.data * 8/1024 AS data,      
                           (CASE WHEN (a1.used ) > a1.data THEN (a1.used ) - a1.data ELSE 0 END) * 8 /1024AS index_size,      
(CASE WHEN (a1.reserved ) > a1.used THEN (a1.reserved ) - a1.used ELSE 0 END) * 8/1024 AS unused,      
        getdate() as reg_dt,      
      -- ep.name as logical_name,  
      --convert(nvarchar(512),ep.value) as ext_prop 
	 (select top 1 name from  SYS.EXTENDED_PROPERTIES where major_id = a2.object_id and minor_id =0 ) as logical_name,
	 (select top 1 convert(nvarchar(512),value) from  SYS.EXTENDED_PROPERTIES where major_id = a2.object_id and minor_id =0 ) as ext_prop
FROM         (SELECT     
                           ps.object_id,      
                           SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END     ) AS [rows],      
 SUM (ps.reserved_page_count) AS reserved,      
                           SUM (      
                                   CASE      
                                   WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)      
                                   ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)      
                                   END      
                           ) AS data,      
                           SUM (ps.used_page_count) AS used   
    FROM sys.dm_db_partition_stats ps      
    GROUP BY ps.object_id) AS a1      
    INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )     
--LEFT JOIN SYS.EXTENDED_PROPERTIES AS EP ON EP.MAJOR_ID = a2.OBJECT_ID  and  ep.minor_id=0     
    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)      
WHERE  a2.type <> ''S'' and a2.type <> ''IT'''        
              
 
      
INSERT INTO #TEMP_TABLE2 (DB_NAME)  
SELECT name
from master..sysdatabases with (nolock)           
where name not in       
    ('northwind', 'pubs', 'LiteSpeedCentral', 'LiteSpeedLocal')      
    and name not like 'sharepoint%'  
    and name not like 'unused%'  
    and DATABASEPROPERTYEX(name,'status')='ONLINE' and dbid  > 4      
                   

DECLARE @MAX_CNT INT  
DECLARE @I INT  
  
SELECT @MAX_CNT = MAX(SEQ)  
FROM #TEMP_TABLE2  
  
SET @I = 1  
  
  
WHILE (@I <= @MAX_CNT)  
  
BEGIN  
  
SELECT @dbname = DB_NAME  
FROM #TEMP_TABLE2  
WHERE SEQ = @I  


            
SET @str_sql = N' USE [' + @dbname + '] ' + char(10)      
            + @str_sql1      
--print @str_sql      
INSERT #temp_table EXEC (@str_sql)       

SET @str_sql = ''      
SET @I = @I + 1  
            
END        
      
      
select server_id, instance_id, rank, db_id, db_name, object_id, schema_name, table_name,      
    row_count, reserved, data, index_size, unused, reg_dt,logical_name,ext_prop from  #temp_table      
    order by db_name      
                             
          
drop table #temp_table
DROP TABLE #temp_table2  
          
RETURN   

