USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_SWITCH_PARTITION]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 실행 예
exec UP_SWITCH_PARTITION
	@table_name = 'DB_MON_BLOCKING',
	@column_name = 'reg_date'
또는 
exec UP_SWITCH_PARTITION
	@table_name = 'DB_MON_BLOCKING'
*/
CREATE PROCEDURE [dbo].[UP_SWITCH_PARTITION] 
	@table_name		sysname,
	@column_name	sysname = 'reg_date'
AS
BEGIN
SET NOCOUNT ON

if not exists (select * from sys.tables where name = @table_name) 
begin
	raiserror('테이블이 존재하지 않습니다.', 16, 1)
	return
end

declare @min_value datetime, @max_value datetime, @new_value datetime
declare @term int
declare @script nvarchar(500)

declare @function_name nvarchar(256), @scheme_name nvarchar(256)
declare @switch_table_name sysname
--set @function_name = 'PF__' + @table_name + '__' + @column_name
--set @scheme_name = 'PS__' + @table_name + '__' + @column_name
set @switch_table_name = 'SWITCH_' + @table_name


select  distinct  @scheme_name = ps.name, @function_name= pf.name
    from sys.dm_db_partition_stats as s with (nolock)
        inner join sys.indexes i  with (nolock) ON i.OBJECT_ID = s.OBJECT_ID AND i.index_id = s.index_id
        inner join sys.partition_schemes as ps  with (nolock)on ps.data_space_id = i.data_space_id 
        inner join sys.partition_functions as pf with (nolock) on pf.function_id = ps.function_id
where s.object_id = object_id(@table_name)




select @min_value = min(convert(datetime, value))
	 , @max_value = max(convert(datetime, value))
	 , @term = datediff(day, min(convert(datetime, value)), max(convert(datetime, value))) / (count(*) - 1)
from sys.partition_range_values v  with (nolock) JOIN sys.partition_functions f  with (nolock)ON v.function_id = f.function_id
where f.name = @function_name



if @max_value < GETDATE() 
begin

	set @new_value = DATEADD(day, @term, @max_value)
	
	set @script = 'ALTER TABLE ' + @table_name + ' SWITCH PARTITION 1 TO SWITCH_' + @table_name
	
	exec (@script)
	
	set @script = 'TRUNCATE TABLE SWITCH_' + @table_name
    exec (@script)	

	set @script = 'ALTER PARTITION SCHEME ' + @scheme_name + ' NEXT USED [PRIMARY]'
	
	exec (@script)	
	
	set @script = 'ALTER PARTITION FUNCTION ' + @function_name + '() MERGE RANGE (''' + CONVERT(char(10), @min_value, 121) + ''')'
	
	exec (@script)	
	
	set @script = 'ALTER PARTITION FUNCTION ' + @function_name + '() SPLIT RANGE (''' + CONVERT(char(10), @new_value, 121) + ''')'
	
	exec (@script)	

end

END


GO
