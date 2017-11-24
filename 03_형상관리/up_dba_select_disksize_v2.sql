use dba
go

ALTER PROC [up_dba_select_disksize]
	@server_id		int,
	@instance_id	int
AS

set nocount on 

declare @svrName varchar(255)
declare @sql varchar(400)
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'

--creating a temporary table
declare @output table
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert @output
EXEC xp_cmdshell @sql


select @server_id as server_id, @instance_id as instance_id
	  , convert(char(1), rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -3))) ) as letter
      ,convert(int,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,(CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as float),0)) as 'disk_size'
	  ,convert(int,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,(CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as float),0) ) - 
	   - convert(int,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,(CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as float)  ,0) ) as 'usage_size'
      --,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,(CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float)  ,0)as 'freespace(GB)'
from @output
where line like '[A-Z][:]%'
order by letter