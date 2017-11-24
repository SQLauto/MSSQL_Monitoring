

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*************************************************************************  
* 프로시저명  : dbo.up_dba_table_size 
* 작성정보    : 2009-08-07 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    : 테이블 별 사이즈가 아닌 DB전체의 사용자 테이블 사이즈
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_table_size
    @db_name sysname

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @command varchar(200)
declare @sql nvarchar(1000)

/* BODY */
truncate table master.dbo.TABLE_FILE_SIZE

set @command = 'insert into master.dbo.TABLE_FILE_SIZE(nbr_of_rows, data_space, index_space) exec '+ @db_name + '.dbo.sp_mstablespace ''?'''


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
SELECT   sum(data_space) /1024 data_space, sum(index_space) /1024 as index_space, 
        (sum(data_space)  +   sum(index_space)) /1024 as total_size
FROM master.dbo.TABLE_FILE_SIZE



RETURN

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO