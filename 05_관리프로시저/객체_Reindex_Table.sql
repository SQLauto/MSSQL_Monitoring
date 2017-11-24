/*******************************************************
 STAGINGDB1에 생성
********************************************************/

use dbadmin
go

CREATE TABLE DBA_REINDEX_TARGET
( 
    id int   IDENTITY (1 , 1)  NOT NULL   , 
    table_name nvarchar (128)   NULL   , 
    database_id smallint    NULL   , 
    database_name nvarchar(128) NULL,
    object_id int    NULL   , 
    index_id int    NULL   , 
    index_name nvarchar(128) NULL,
    partition_number int    NULL   , 
    index_type_desc nvarchar (60)   NULL   , 
    alloc_unit_type_desc nvarchar (60)   NULL   , 
    index_depth tinyint    NULL   , 
    index_level tinyint    NULL   , 
    avg_fragmentation_in_percent float    NULL   , 
    fragment_count bigint    NULL   , 
    avg_fragment_size_in_pages float    NULL   , 
    page_count bigint    NULL   , 
    avg_page_space_used_in_percent float    NULL   , 
    record_count bigint    NULL   , 
    ghost_record_count bigint    NULL   , 
    version_ghost_record_count bigint    NULL   , 
    min_record_size_in_bytes int    NULL   , 
    max_record_size_in_bytes int    NULL   , 
    avg_record_size_in_bytes float    NULL   , 
    forwarded_record_count bigint    NULL   , 
    reg_date             datetime   NOT NULL   CONSTRAINT DF__DBA_REINDEX_TARGET__REG_DATE DEFAULT(getdate()) , 
    execute_status       char (1)   NULL  
)  ON [PRIMARY]
GO




ALTER TABLE DBA_REINDEX_TARGET ADD CONSTRAINT PK__DBA_REINDEX_TARGET
primary key clustered ([id], reg_date ASC ) ON [PRIMARY] 
GO


/**********************************************************
 각 장비에 생성
***********************************************************/
use dbadmin
go

CREATE TABLE DBA_REINDEX_SPACE
( 
    id int    NOT NULL   , 
    database_name nvarchar (125)   NULL   , 
    table_name nvarchar (125)   NULL   , 
    index_name nvarchar (125)   NULL   , 
    before_dpages bigint    NULL   , 
    before_reserved bigint    NULL   , 
    before_used bigint    NULL   , 
    before_rowcnt bigint    NULL   , 
    before_rowmodctr bigint    NULL   , 
    after_dpages bigint    NULL   , 
    after_reserved bigint    NULL   , 
    after_used bigint    NULL   , 
    after_rowcnt bigint    NULL   , 
    after_rowmodctr bigint    NULL   , 
    start_date datetime    NULL   , 
    end_date datetime    NULL   , 
    duration bigint    NULL  
)  ON [PRIMARY]
GO


ALTER TABLE DBA_REINDEX_SPACE ADD CONSTRAINT 
    PK__DBA_REINDEX_SPACE__ID primary key clustered ([id] ASC ) ON [PRIMARY] 
GO


--=============================================
-- 수집 SP
--=============================================
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.up_dba_index_physical_stats
* 작성정보    : 2010-08-12 by choi bo ra
* 관련페이지  : 
* 내용        :  exec dbo.up_dba_index_physical_stats 'itemdb1', 50
* 수정정보    : 
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_index_physical_stats 
    @db_name        nvarchar(128),
    @Percentage     int = 80,
    @mode           nvarchar(10) = 'SAMPLED'
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @MSQL  NVARCHAR(4000)
DECLARE @SQL  NVARCHAR(1000)

/* BODY */
SET @MSQL = N'DECLARE @object_id  INT' + char(10)
            + N'USE ' + @db_name 
            + N'
            DECLARE vCursor CURSOR LOCAL STATIC FOR
            
                SELECT object_id FROM SYS.TABLES WITH (NOLOCK)  ORDER BY object_id
            OPEN vCursor;
            FETCH NEXT FROM vCursor INTO @object_id;
            WHILE (@@FETCH_STATUS = 0 )
            BEGIN
                INSERT INTO  DBADMIN.dbo.DBA_REINDEX_TARGET(
                    table_name
                    ,database_id
                    ,database_name
                    ,object_id
                    ,index_id
                    ,index_name
                    ,partition_number
                    ,index_type_desc
                    ,alloc_unit_type_desc
                    ,index_depth
                    ,index_level
                    ,avg_fragmentation_in_percent
                    ,fragment_count
                    ,avg_fragment_size_in_pages
                    ,page_count
                    ,avg_page_space_used_in_percent
                    ,record_count
                    ,ghost_record_count
                    ,version_ghost_record_count
                    ,min_record_size_in_bytes
                    ,max_record_size_in_bytes
                    ,avg_record_size_in_bytes
                    ,forwarded_record_count)
                SELECT object_name(IPS.object_id) AS table_name, 
                    db_id('''+ @db_name + ''') as db_id, '''+ @db_name + ''' as database_name,
                	ST.object_id as object_id,
                	SI.index_id as index_id,
                	SI.name as index_name, 
                	IPS.partition_number,
                	IPS.index_type_desc,
                	IPS.alloc_unit_type_desc,
                	IPS.index_depth,
                	IPS.index_level,
                	IPS.avg_fragmentation_in_percent,
                	IPS.fragment_count,
                	IPS.avg_fragment_size_in_pages,
                	IPS.page_count,
                	IPS.avg_page_space_used_in_percent,
                	IPS.record_count,
                	IPS.ghost_record_count,
                	IPS.version_ghost_record_count,
                	IPS.min_record_size_in_bytes,
                	IPS.max_record_size_in_bytes,
                	IPS.avg_record_size_in_bytes,
                	IPS.forwarded_record_count
                FROM sys.dm_db_index_physical_stats(db_id(''' + @db_name + '''), @object_id , NULL, NULL ,'''+ @mode +''') IPS
                   JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id
                   JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id
                WHERE ST.is_ms_shipped = 0
                	AND avg_fragmentation_in_percent > ' + convert(char(3), @Percentage) + CHAR(13)
             + N'FETCH NEXT FROM vCursor INTO @object_id;
                END;
                CLOSE vCursor;
                DEALLOCATE vCursor;'
           --print @MSQL
           EXEC sp_ExecuteSQL @MSQL;


RETURN
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



/* 인덱스 rebuild 작업 처리 
    choi bo ra
*/

ALTER PROC [dbo].[up_dba_reindexes]          
	 @database_name varchar(125)    
	,@table_name varchar(125)    
	,@avg_fragmentation_in_percent int = 50                
	,@Min_page_count int = 1024          
as          
          
SET NOCOUNT ON;          
SET query_governor_cost_limit 0;            
          
DECLARE @id int;          
DECLARE @dbid int;          
DECLARE @objectid int;          
DECLARE @indexid int;          
DECLARE @command nvarchar(4000);           
DECLARE @start_date datetime;          
DECLARE @end_date datetime;          
          
DECLARE @dbname nvarchar(130);           
DECLARE @objectname nvarchar(130);           
DECLARE @schemaname nvarchar(130);           
DECLARE @index_name nvarchar(130);           
DECLARE @partitionnum bigint;          
DECLARE @partitions bigint;          
          
DECLARE @before_dpages bigint;           
DECLARE @before_reserved bigint;          
DECLARE @before_used bigint;           
DECLARE @before_rowcnt bigint;           
DECLARE @before_rowmodctr bigint;          
          
DECLARE @after_dpages bigint;           
DECLARE @after_reserved bigint;          
DECLARE @after_used bigint;           
DECLARE @after_rowcnt bigint;           
DECLARE @after_rowmodctr bigint;          
          
DECLARE @partitioncount bigint;          
                  
WHILE (1=1)          
BEGIN          
 SELECT TOP 1          
   @id = id          
  ,@dbid = database_id          
  ,@objectid = object_id           
  ,@indexid = index_id        
  ,@index_name = QUOTENAME(index_name)  
 FROM dbo.DBA_REINDEX_TARGET        
 WHERE            
    execute_status is null      
   AND avg_fragmentation_in_percent > @avg_fragmentation_in_percent            
   AND database_name = @database_name 
   AND (@table_name  = '' and table_name = table_name or table_name = @table_name )       
   AND partition_number = 1          
   --AND index_type_desc = 'NONCLUSTERED INDEX'    
   --AND page_count > 1024        
 ORDER BY avg_page_space_used_in_percent 
      
 IF @@ROWCOUNT = 0           
  RETURN;   
  
 DECLARE @SCRIPT NVARCHAR(1000) 
 DECLARE @PARAM  nvarchar(200)   
          
 IF  @id is not null          
 BEGIN   
 
      SET @script = 'USE ' + @database_name 
                    + ' SELECT '         
                    + ' @before_dpages = dpages'           
                    + ',@before_reserved  = reserved'          
                    + ',@before_used = used'          
                    + ',@before_rowcnt = rowcnt'          
                    + ',@before_rowmodctr = rowmodctr'                 
                    + ' FROM ' + @database_name + '.SYS.sysindexes '          
                    + ' WHERE id =' + convert(nvarchar(10), @objectid) + ' AND indid = ' + convert(nvarchar(10),  @indexid )               
                       
     SET @PARAM = '@before_dpages BIGINT OUTPUT, @before_reserved BIGINT OUTPUT, @before_used BIGINT OUTPUT, @before_rowcnt BIGINT OUTPUT'
                  +', @before_rowmodctr BIGINT OUTPUT'
     SET @start_date = getdate()
        
    EXEC sp_executesql @SCRIPT, @PARAM, @before_dpages =@before_dpages output 
               , @before_reserved = @before_reserved output, @before_used = @before_used output
               , @before_rowcnt =@before_rowcnt output, @before_rowmodctr =@before_rowmodctr output

    IF @@ERROR <> 0 RETURN
    UPDATE dbo.DBA_REINDEX_TARGET SET Execute_Status = 'P' WHERE id = @id           
  
   SET @script = 'USE ' + @database_name 
                + ' SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name) '          
                + ' FROM ' + @database_name + '.sys.objects AS o ' + char(10)         
                + ' JOIN ' + @database_name + '.sys.schemas as s ON s.schema_id = o.schema_id'         
                + ' WHERE o.object_id = ' + convert(nvarchar(10), @objectid )    
                
    SET @PARAM = '@objectname nvarchar(100) OUTPUT, @schemaname nvarchar(10) OUTPUT'
   EXEC sp_executesql @SCRIPT, @PARAM, @objectname = @objectname output, @schemaname  =@schemaname output
   IF @@ERROR <> 0 RETURN
   
   SET @command =  N'ALTER INDEX ' + @index_name + N' ON ' + @database_name + N'.' + @schemaname + N'.' + @objectname + N' REBUILD WITH (ONLINE = ON, MAXDOP=8 )';           
   
   print @command
  
   BEGIN TRY
    EXEC (@command);
   END TRY
   BEGIN CATCH
       IF ERROR_NUMBER() = 2725 -- nvarchar(max), xml ,text 유형일 때
       continue;
   END CATCH
   
    
   IF @@ERROR <> 0 RETURN
   
    SET @script = 'USE ' + @database_name 
                    + ' SELECT '         
                    + ' @after_dpages = dpages'           
                    + ',@after_reserved  = reserved'          
                    + ',@after_used = used'          
                    + ',@after_rowcnt = rowcnt'          
                    + ',@after_rowmodctr = rowmodctr'                 
                    + ' FROM ' + @database_name + '.SYS.sysindexes '          
                    + ' WHERE id =' + convert(nvarchar(10), @objectid) + ' AND indid = ' + convert(nvarchar(10),  @indexid )               
                       
     SET @PARAM = '@after_dpages BIGINT OUTPUT, @after_reserved BIGINT OUTPUT, @after_used BIGINT OUTPUT, @after_rowcnt BIGINT OUTPUT'
                  +', @after_rowmodctr BIGINT OUTPUT'
     SET @end_date = getdate()
        
    EXEC sp_executesql @SCRIPT, @PARAM, @after_dpages =@after_dpages output 
               , @after_reserved = @after_reserved output, @after_used = @after_used output
               , @after_rowcnt =@after_rowcnt output, @after_rowmodctr =@after_rowmodctr output         
  
   IF @@ERROR <> 0 RETURN
            
  INSERT  DBO.DBA_REINDEX_SPACE         
  (          
    id,database_name,table_name,index_name,before_dpages,before_reserved,before_used          
   ,before_rowcnt,before_rowmodctr,after_dpages,after_reserved,after_used,after_rowcnt,after_rowmodctr          
   ,start_date,end_date,duration            
  )          
  VALUES          
  (          
   @id, @database_name, @objectname, @index_name,@before_dpages,@before_reserved,@before_used          
   ,@before_rowcnt,@before_rowmodctr,@after_dpages,@after_reserved,@after_used,@after_rowcnt,@after_rowmodctr          
   ,@start_date,@end_date,datediff(s, @start_date, @end_date)              
  )     
  

       
  UPDATE dbo.DBA_REINDEX_TARGET SET  execute_status = 'E'  WHERE id = @id           
 END          
END   
GO


--==============================================
-- 예상 사이즈
--==============================================
--avg_page_space_used_in_percent가90으로채워진다고가정할경우예상사이즈감소
declare @frag_percent int
set @frag_percent = 90
select sum((90 - a.avg_page_space_used_in_percent)*a.page_count/100/128)/1024 as free_space_GB
, count(*) as index_count
from dbadmin.DBO.DBA_REINDEX_TARGET a with(nolock)
inner join sys.indexes b on a.object_id = b.object_id and a.index_id=b.index_id
inner join sys.filegroups c on b.data_space_id=c.data_space_id
where a.database_id = 12 and a.index_id > 1 
and avg_fragmentation_in_percent > @frag_percent
and alloc_unit_type_desc='IN_ROW_DATA'



--정보보기
select  c.name as filegroupname, a.database_name , table_name,
b.name as index_name, a.index_id, b.type_desc,
a.page_count, 
a.page_count/128/1024. as page_GB,
a.fragment_count/128/1024. as fragment_GB,
a.avg_fragmentation_in_percent,
a.avg_fragment_size_in_pages,
a.avg_page_space_used_in_percent,
90 - a.avg_page_space_used_in_percent as after_free_space_ratio
, (90 - a.avg_page_space_used_in_percent)*a.page_count/100/128 as free_space_MB
from dbadmin.DBO.DBA_REINDEX_TARGET a with(nolock)
inner join sys.indexes b on a.object_id = b.object_id and a.index_id=b.index_id
inner join sys.filegroups c on b.data_space_id=c.data_space_id
where  a.index_id>1 --and avg_fragmentation_in_percent > 70
and alloc_unit_type_desc='IN_ROW_DATA'
order by avg_fragmentation_in_percent desc