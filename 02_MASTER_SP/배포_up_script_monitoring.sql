create procedure up_script_monitoring
as

SET NOCOUNT ON

print 'use dbadmin'
print 'go'

print 'set nocount on'

declare @script nvarchar(3000)

set @script = ''

exec sp_script_table_create 'dba_mon',  @script = @script output

print @script
print 'go'


exec sp_script_data_insert 'dba_mon'
print 'go'

print 'use master'
print 'go'

declare @seq int, @max int
declare @sp_name sysname
declare @sp_seq int, @sp_max int


declare @proc_list table (
	seq int identity(1, 1) primary key,
	sp_name sysname
)

create table #script_list (
	seq int identity(1, 1) primary key,
	script varchar(2000)
)

insert @proc_list (sp_name)
select sp_name from dba_mon where sp_type = 1
order by seq_no

select @seq = 1, @max = @@rowcount

while @seq <= @max
begin
	select @sp_name = sp_name from @proc_list where seq = @seq

	print 'if object_id(''' + @sp_name + ''') is not null drop procedure ' + @sp_name
	print 'go'

	SET @seq = @seq + 1

end

set @seq = 1

while @seq <= @max
begin
	select @sp_name = sp_name from @proc_list where seq = @seq

	insert  #script_list (script) 
	exec master.dbo.sp_helptext @sp_name

	select @sp_seq = 1, @sp_max = @@rowcount

	while @sp_seq <= @sp_max 
	begin
		select @script = script from #script_list where seq = @sp_seq
	
		print @script

		set @sp_seq = @sp_seq + 1

	end
		
	truncate table #script_list

	print 'go'

	SET @seq = @seq + 1

end


drop table #script_list


