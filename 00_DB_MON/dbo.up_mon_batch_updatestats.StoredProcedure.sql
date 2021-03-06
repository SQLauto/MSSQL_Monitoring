USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[up_mon_batch_updatestats]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************    
* 프로시저명  : dbo.up_mon_batch_updatestats  
* 작성정보    : 2011-03-17 by choi bo ra  
* 관련페이지  :   
* 내용        : 해당 DB의 통계 정보 갱신  
* 수정정보    : up_mon_batch_updatestats 'tiger'  
**************************************************************************/  
CREATE PROCEDURE [dbo].[up_mon_batch_updatestats]   
    @DBName     sysname,  
    @rowcount   int = 100000  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
SET QUERY_GOVERNOR_COST_LIMIT 0;    
  
/* USER DECLARE */  
DECLARE @vSQL NVARCHAR(4000);    
  
/* BODY */  
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)  
BEGIN  
 SET @vSQL = N'The database' + ' (' + @DBName + ') ' + 'does not exist'  
 RAISERROR(@vSQL, 16, 127)   
 RETURN  
END  
  
SET @vSQl =  
        N'DECLARE @vSQL NVARCHAR(2000); ' + char(10)  
    +   'USE ' + @DBName + ';' + char(10)  
    + char(10)      
	+   'DECLARE @object_id int, @ind_name VARCHAR(100), @table_name VARCHAR(100);'+ char(10)  
    +   'DECLARE vCursor CURSOR LOCAL STATIC FOR ' + char(10)  
    +   'SELECT ''UPDATE STATISTICS ''+ schema_name(sch.schema_id)  +  ''.[''  + obj.name + ''] (['' + ind.name  + ''])'' , ind.id, ind.name, obj.name' + char(10)  
    +   'FROM SYS.SYSINDEXES as ind with (nolock) ' + char(10)  
    +   'INNER JOIN SYS.OBJECTS as obj  with (nolock) on obj.object_id = ind.id ' + char(10)  
    +   'INNER JOIN SYS.SCHEMAS as sch with (nolock) on sch.schema_id = obj.schema_id ' + char(10)  
    +   'INNER JOIN sys.dm_db_index_usage_stats dmv1 with(nolock) on ind.indid =dmv1.index_id ' + char(10)  
    +   '       and obj.object_id = dmv1.object_id' + char(10)  
    +   'INNER JOIN sys.stats AS stat with(nolock) on stat.object_id = ind.id AND ind.indid = stat.stats_id ' + char(10)  
    +   'WHERE ind.name IS NOT NULL ' + char(10)  
    +   'AND obj.name NOT LIKE ''sys%'' ' + char(10)  
    +   'AND left(ind.name,1) != ''_''' + char(10)  
    +   'AND left(ind.name,1) != ''_''' + char(10)  
    +   'AND ind.rowmodctr > ' + convert(nvarchar(20), @rowcount) + char(10)  
    +   'AND (( STATS_DATE(ind.id, ind.indid) IS NOT NULL AND dmv1.last_user_update > stats_date(ind.id, ind.indid)) ' + char(10)  
    +   '   OR (stats_date(ind.id, ind.indid) IS NULL)) ' + char(10)  
    +   'AND dmv1.database_id = DB_ID(''' + @DBName + ''') ' + char(10)  
    +   'ORDER BY ind.rowmodctr DESC' + char(10)  
    + char(10)  
    +   'OPEN vCursor;  ' + char(10)  
    +   'FETCH NEXT FROM vCursor INTO @vSQL, @object_id, @ind_name, @table_name; ' + char(10)  
    +   'WHILE (@@FETCH_STATUS = 0) ' + char(10)  
    +   'BEGIN' + char(10)  
    +	'IF EXISTS(select * from sys.indexes WITH(NOLOCK) WHERE object_id = @object_id and name = @ind_name and object_name(object_id) = @table_name)'+ char(10)      
    +	'BEGIN'  + char(10)  
    +   '   EXEC sp_ExecuteSQL @vSQL;  ' + char(10)  
    +   '   IF @@ERROR != 0 AND @@ERROR != 2727 GOTO ERROR_HANDLER  ' + char(10)         
    +	'END'  + char(10)    
    +	'	FETCH NEXT FROM vCursor INTO @vSQL, @object_id, @ind_name, @table_name;  ' + char(10)  
    +   'END;' + char(10)  
    +   'CLOSE vCursor;' + char(10)   
    +   'DEALLOCATE vCursor;' + char(10)  
    +   'RETURN' + char(10)  
    +   'ERROR_HANDLER:' + char(10)      
--    +   '   ROLLBACK ' + char(10)  
    +   '   DECLARE @ErrorString varchar(2000) ' + char(10)  
    +   '   SET @ErrorString = ''ERROR_NUMBER:'' + CONVERT(VARCHAR(10),ERROR_NUMBER()) + CHAR(10)  ' + CHAR(10)  
    +   '         + ''LINE:''+CONVERT(VARCHAR(100),ERROR_LINE()) + CHAR(10) ' + CHAR(10)  
    +   '         + ''MESSAGE:''+CONVERT(VARCHAR(800),ERROR_MESSAGE()) + CHAR(10)  ' + char(10)  
    +   ' RAISERROR (@ErrorString, 15, 127) ' + CHAR(10)      
  
--PRINT @vSQL;  
EXEC sp_ExecuteSQL @vSQL;    
      
RETURN 


GO
