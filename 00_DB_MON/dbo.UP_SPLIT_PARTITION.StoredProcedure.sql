USE [DBMON]
GO
/****** Object:  StoredProcedure [dbo].[UP_SPLIT_PARTITION]    Script Date: 2014-11-10 오후 4:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UP_SPLIT_PARTITION]
	@table_name		sysname,
	@type char(1), --P:과거, F:미래
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



select  distinct  @scheme_name = ps.name, @function_name= pf.name
    from sys.dm_db_partition_stats as s
        inner join sys.indexes i  ON i.OBJECT_ID = s.OBJECT_ID AND i.index_id = s.index_id
        inner join sys.partition_schemes as ps on ps.data_space_id = i.data_space_id 
        inner join sys.partition_functions as pf on pf.function_id = ps.function_id
where s.object_id = object_id(@table_name)


select @min_value = min(convert(datetime, value))
	 , @max_value = max(convert(datetime, value))
	 , @term = datediff(day, min(convert(datetime, value)), max(convert(datetime, value))) / (count(*) - 1)
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = @function_name



if @type = 'P'
	set @new_value = DATEADD(day, @term*-1, @min_value)
else
	set @new_value = DATEADD(day, @term, @max_value)


	
set @script = 'ALTER PARTITION SCHEME ' + @scheme_name + ' NEXT USED [PRIMARY]'
exec (@script)	
	

set @script = 'ALTER PARTITION FUNCTION ' + @function_name + '() SPLIT RANGE (''' + CONVERT(char(10), @new_value, 121) + ''')'
	exec (@script)	


END
GO
