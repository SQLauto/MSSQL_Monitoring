CREATE procedure sp_mon_change_procedure
	@duration int = 60
as

set nocount on

declare @seq int, @max int
declare @dbname sysname
declare @script nvarchar(1024)

declare @db_list table (
	seq int IDENTITY(1, 1) PRIMARY KEY,
	dbname	sysname
)

declare @proc_list table (
	seq int IDENTITY(1, 1) PRIMARY KEY,
	dbname	sysname,
	objectname sysname,
	type	char(6),
	create_date datetime,
	modify_date	datetime
)

insert @db_list (dbname)
select name from sys.databases where name NOT IN ('master', 'tempdb', 'model', 'msdb')

select @seq = 1, @max = @@rowcount

while @seq <= @max
begin

	select @dbname = dbname from @db_list where seq = @seq

	set @script = 'select ''' + @dbname + ''' as dbname, name, case when create_date = modify_date then ''CREATE'' else ''MODIFY'' end, create_date, modify_date from ' + @dbname + '.sys.procedures where create_date > dateadd(minute, (-1) * ' + convert(varcha
r, @duration) + ', getdate()) and modify_date > dateadd(minute, (-1) * ' + convert(varchar, @duration) + ', getdate())'

	insert @proc_list (dbname, objectname, type, create_date, modify_date)
	exec (@script)

	set @seq = @seq + 1

end

if exists (select * from @proc_list) 
	select * from @proc_list
else
	print '1시간 이내에 생성, 수정된 프로시져가 존재하지 않습니다!!'

