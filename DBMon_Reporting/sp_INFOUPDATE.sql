CREATE PROCEDURE [dbo].[sp_INFOUPDATE](@pagesize int = 20, @flag bit = 1)
AS
set nocount on 
declare @vsql nvarchar(2000)
declare @vpath nvarchar(2000)
declare @vfilename nvarchar(2000)

declare @vint int
declare @page int

set @page = 1
set @vint = 0

IF not exists(select 1 from tempdb.dbo.sysobjects where name = '##tmp')
	CREATE TABLE ##tmp(dbname varchar(50),cmd varchar(4000),rownumber int)
IF not exists(select 1 from tempdb.dbo.sysobjects where name = '##osql')
	CREATE TABLE ##osql(dbname varchar(50), cmd varchar(4000))

if @flag = 0 
begin
	with dc as
	(
	select 'DBCC UPDATEUSAGE('''+db_name()+''','''+ user_name(uid)+'.'+name+''')' cmd,
	row_number() over(order by name) as rownumber
	from sysobjects
	where xtype='U'
	)
	insert into ##tmp select db_name(),cmd,rownumber from dc
	SET	@vFileName = 'UpdateUsage'
end
else
begin
	with dc as
	(
	select 'UPDATE STATISTICS '+db_name()+'.'+ user_name(uid)+'.'+name+'' cmd,
	row_number() over(order by name) as rownumber
	from sysobjects
	where xtype='U'
	)
	insert into ##tmp select db_name(), cmd,rownumber from dc
	SET	@vFileName = 'UpdateStatistics'
end

select @vint = ceiling(count(*) / @pagesize / 1.0) from ##tmp
SELECT @vpath = 'mkdir c:\temp\' + db_name()

EXEC master.dbo.xp_cmdshell @vpath, no_output
SELECT @vpath = 'c:\temp\' + db_name() + '\'


while (@page <= @vint)
begin
	set @vsql = 'bcp "select cmd from ##tmp where dbname = ''' +db_name()+''' and rownumber between '+cast((@page-1) * @pagesize as varchar(200)) + ' and ' + cast(@pagesize * @page as varchar(200)) +'" queryout ' + @vpath + @vFileName + cast(@page as varchar(10))+'.sql -S(local) -T -c' 
	EXEC master.dbo.xp_cmdshell @vsql,no_output
	
	set @vsql = 'start osql -i ' + @vpath + @vFileName + cast(@page as varchar(10))+'.sql -S(local) -E -o ' + @vpath + 'Log@' + @vFileName + cast(@page as varchar(10))+ '.log'
    print @vsql
	insert into ##osql values(db_name(),@vsql)
	set @page = @page + 1
end

delete from ##tmp where dbname = db_name()

set @vsql = 'bcp "select cmd from ##osql where dbname = ''' + db_name() + '''" queryout ' + @vpath + db_name() + @vFileName + '.cmd -S(local) -T -c' 
EXEC master.dbo.xp_cmdshell @vsql,no_output
delete from ##osql where dbname = db_name()

--set @vsql = @vpath + db_name() + @vFileName +'.cmd'
--EXEC master.dbo.xp_cmdshell @vsql,no_output
RETURN