

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_dbsize 
* 작성정보    : 2009-07-30 by choi bo ra
* 관련페이지  : DB별 용량
* 내용        :
* 수정정보    : exec up_dba_dbsize 'CREDIT'
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_dbsize
     @db_name       sysname = 'master'

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE	@cmd nvarchar(1000)          -- various commands
DECLARE	@crlf char(2)               -- carriage return line feed
declare @command varchar(200)
declare @sql nvarchar(1000)

SET		@crlf = CHAR(13) + CHAR(10)



/* BODY */


--	SELECT @cmd = 
--
--	N'USE [' + @db_name + N']' +  @crlf + 
--	N'SET NOCOUNT ON' + @crlf + 
--   -- N'INSERT INTO @Databases (db_type, dbsize,freesize) ' +  @crlf +
--	N'SELECT case when f.type = 1 then ''LOG'' else ''DATA'' end as type, ' +  @crlf + 
--    N'sum(CAST(sysfiles.size/128.0 AS int)) AS dbsize, '  +  @crlf + 
--    N'sum(CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ''SpaceUsed'' ) AS int)/128.0 AS int)) AS freesize '  +  @crlf + 
--    N'FROM dbo.sysfiles' +  @crlf + 
--    N'inner join sys.database_files as f on sysfiles.fileid = f.file_id'  +  @crlf + 
--    N'group by f.type'
--
--
--exec sp_executesql @cmd

/* BODY */
truncate table master.dbo.TABLE_FILE_SIZE

set @command = 'insert into master.dbo.TABLE_FILE_SIZE (nbr_of_rows, data_space, index_space) exec '+ @db_name + '.dbo.sp_mstablespace ''?'''


-- Get all tables, names, and sizes
set @sql = @db_name + 
        N'.dbo.sp_msforeachtable @command1= "' + @command  + '"'
         --'",@command2="update #temp_table set table_name = ''?'' where rec_id = (select max(rec_id) from TABLE_FILE_SIZE)"'

EXECUTE sp_executesql @sql

--EXEC sp_msforeachtable 
--        @command1= @command,
--        @command2="update #temp_table set table_name = '?' where rec_id = (select max(rec_id) from #temp_table)"

---- Set the total_size and total database size fields
--UPDATE #temp_table
--SET total_size = (data_space + index_space), db_size = (SELECT SUM(data_space + index_space) FROM #temp_table)
--
---- Set the percent of the total database size
--UPDATE #temp_table
--SET percent_of_db = (total_size/db_size) * 100

-- Get the data
UPDATE TABLE_FILE_SIZE SET dbname = @db_name



SELECT  d.file_type, d.total_data_size, d.use_data, d.free_data,
        t.total_size, t.data_size, t.index_size
FROM  (select dbname, (sum(data_space)  +   sum(index_space)) /1024 as total_size,
              sum(data_space) /1024 data_size, sum(index_space) /1024 as index_size
       from  master.dbo.TABLE_FILE_SIZE with (nolock) group by dbname ) as t
    inner join  
      (select dbname, file_type, sum(total_data_size) as total_data_size, sum(use_data) as use_data,
               (sum(total_data_size) - sum(use_data)) as free_data
       FROM DB_FILE_SIZE with (nolock) WHERE dbname = @db_name GROUP BY dbname, file_type) as d
    on t.dbname = d.dbname
     
RETURN


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

