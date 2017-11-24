CREATE PROC dbo.sp_sqldiag @bGetSyscacheobjects int = 0 
AS

PRINT 'Errorlogs'
PRINT '---------'

exec master.dbo.xp_readerrorlog 
exec master.dbo.xp_readerrorlog 1
exec master.dbo.xp_readerrorlog 2
exec master.dbo.xp_readerrorlog 3
exec master.dbo.xp_readerrorlog 4
exec master.dbo.xp_readerrorlog 5
exec master.dbo.xp_readerrorlog 6

PRINT 'Registry Information'
PRINT '--------------------'

PRINT 'SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo:'
PRINT '------------------------------------------------'
EXEC master.dbo.sp_tmpregenumvalues 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\MSSQLServer\Client\ConnectTo'
PRINT ''

PRINT 'SOFTWARE\Microsoft\MSSQLServer\Client\DB-Lib:'
PRINT '---------------------------------------------'
EXEC master.dbo.sp_tmpregenumvalues 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\Client\DB-Lib' 
PRINT ''

PRINT 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\CurrentVersion:'
PRINT '----------------------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\CurrentVersion', 'CurrentVersion'
PRINT ''

PRINT 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters:'
PRINT '------------------------------------------------------'
EXEC master.dbo.sp_tmpregenumvalues  'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'
PRINT ''

PRINT 'SOFTWARE\Microsoft\MSSQLServer\Setup\SQLPath:'
PRINT '---------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\Setup', 'SQLPath'
PRINT ''

PRINT 'System\CurrentControlSet\Control\ProductOptions:'
PRINT '------------------------------------------------'
EXEC master.dbo.sp_tmpregenumvalues  'HKEY_LOCAL_MACHINE', 
  'System\CurrentControlSet\Control\ProductOptions', 1
PRINT ''

PRINT 'Software\Microsoft\Windows NT\CurrentVersion\SystemRoot:'
PRINT '--------------------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\Windows NT\CurrentVersion', 'SystemRoot'
PRINT ''

PRINT 'Software\Microsoft\Windows NT\CurrentVersion\CurrentVersion:'
PRINT '------------------------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\Windows NT\CurrentVersion', 'CurrentVersion'
PRINT ''

PRINT 'System\CurrentControlSet\Control\Nls\CodePage:'
PRINT '----------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'System\CurrentControlSet\Control\Nls\CodePage', 'ACP'
PRINT ''

PRINT 'System\CurrentControlSet\Control\Nls\CodePage:'
PRINT '----------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'System\CurrentControlSet\Control\Nls\CodePage', 'OEMCP'
PRINT ''

PRINT 'Software\Microsoft\DataAccess:'
PRINT '------------------------------'
EXEC master.dbo.sp_tmpregenumvalues  'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\DataAccess'
PRINT ''

PRINT 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation\ActiveTimeBias:'
PRINT '--------------------------------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'SYSTEM\CurrentControlSet\Control\TimeZoneInformation', 'ActiveTimeBias'
PRINT ''

PRINT 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation\Bias:'
PRINT '----------------------------------------------------------'
EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE', 
  'SYSTEM\CurrentControlSet\Control\TimeZoneInformation', 'Bias'
PRINT ''

IF (CHARINDEX('7.0',@@VERSION)<>-1) BEGIN
	PRINT 'SYSTEM\CurrentControlSet\Services\LicenseInfo\MSSQL7.00:'
	PRINT '--------------------------------------------------------'
	EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE',
	  'SYSTEM\CurrentControlSet\Services\LicenseInfo\MSSQL7.00', 'ConcurrentLimit'
END ELSE BEGIN
	PRINT 'SOFTWARE\Microsoft\Microsoft SQL Server\80\MSSQLLicenseInfo\MSSQL8.00:'
	PRINT '----------------------------------------------------------------------'
	EXEC master.dbo.sp_tmpregread 'HKEY_LOCAL_MACHINE',
	  'SOFTWARE\Microsoft\Microsoft SQL Server\80\MSSQLLicenseInfo\MSSQL8.00',
	   'ConcurrentLimit'
END
PRINT ''
PRINT ''


PRINT '-> sp_configure'
declare @show_advance int 
if (select value from master.dbo.syscurconfigs where config = 518) = 1 
   select @show_advance = 1 
else 
   select @show_advance = 0 
if @show_advance = 0 
begin 
    exec sp_configure 'show advanced option',1 
    reconfigure with override
    exec sp_configure	
    exec sp_configure 'show advanced option',0 
    reconfigure with override
end 
else 
    exec sp_configure

PRINT '-> sp_who'
exec sp_who
PRINT ''

PRINT '-> sp_lock'
exec sp_lock
PRINT ''

PRINT '-> sp_helpdb'
exec sp_helpdb
PRINT ''

PRINT '-> xp_msver'
exec master.dbo.xp_msver
PRINT ''

PRINT '-> sp_helpextendedproc'
exec sp_helpextendedproc
PRINT ''

PRINT '-> Sysprocesses'
select spid, kpid, blocked, waittype, waittime, lastwaittype, 
  LEFT (waitresource, 50) AS waitresource, dbid, 
  uid, cpu, physical_io, memusage, login_time, last_batch, ecid, open_tran, 
  status, sid, LEFT (hostname, 30) AS hostname, 
  LEFT (program_name, 50) AS program_name, hostprocess, cmd, 
  LEFT (nt_domain, 30) AS nt_domain, LEFT (nt_username, 30) AS nt_username, 
  net_address, net_library, loginame, context_info, sql_handle, 
  stmt_start, stmt_end
from master.dbo.sysprocesses
PRINT ''

-- fn_virtualservernodes is not present in 7.0
IF (CHARINDEX ('Microsoft SQL Server  7.00', @@VERSION) = 0)
BEGIN
    EXEC ('PRINT ''-> ::fn_virtualservernodes()''')
    EXEC ('SELECT * FROM ::fn_virtualservernodes()')
    EXEC ('PRINT ''''')
END

PRINT '-> sysdevices'
SELECT * from master.dbo.sysdevices
PRINT ''

PRINT '-> sysdatabases'
SELECT * from master.dbo.sysdatabases
PRINT ''

--Input buffers
PRINT 'Input buffer SPIDs'

declare @spid smallint
declare @i_buff_string char(30) 
set nocount on   
declare bufCursor CURSOR FOR SELECT spid from master.dbo.sysprocesses where spid > 10
FOR READ ONLY
open bufCursor
fetch next from bufCursor into @spid 
while (@@fetch_status <> -1) 
begin 
    SET @i_buff_string = ('DBCC INPUTBUFFER (' + convert(char(6),@spid) +')') 
    PRINT '-> '+@i_buff_string 
    exec (@i_buff_string) 
		PRINT ''
    fetch next from bufCursor into @spid 
end 
close bufCursor
deallocate bufCursor

PRINT '-> Head blockers'

select spid as [Blocking spid],loginame,hostname,program_name as progname,cmd,status,physical_io,waittype
from master.dbo.sysprocesses 
where spid in (select blocked from master.dbo.sysprocesses)
and blocked=0
PRINT ''

PRINT '-> SELECT @@version:'
PRINT @@VERSION
PRINT ''

PRINT '-> Current login (SUSER_SNAME):'
PRINT SUSER_SNAME ()
PRINT ''

PRINT '-> SQL Server name (@@SERVERNAME):'
PRINT @@SERVERNAME
PRINT ''

PRINT '-> Host (client) machine name (HOST_NAME):'
PRINT HOST_NAME()
PRINT ''

PRINT '-> @@LANGUAGE:'
PRINT @@LANGUAGE
PRINT ''

/*
PRINT '-> DBCC PSS(n):'

DBCC TRACEON (3604)
DECLARE @sp int
DECLARE @cmd varchar(255)
DECLARE spid_curs INSENSITIVE CURSOR  FOR 
  SELECT CONVERT (int, spid) AS spid 
  FROM master.dbo.sysprocesses WHERE spid > 6
OPEN spid_curs
FETCH NEXT FROM spid_curs INTO @sp
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @cmd = 'DBCC PSS (0, ' + CONVERT (varchar, @sp) + ')'
    PRINT '-> ' + @cmd
    EXEC (@cmd)
	  PRINT ''
  END
  FETCH NEXT FROM spid_curs INTO @sp
END
CLOSE spid_curs
DEALLOCATE spid_curs
DBCC TRACEOFF(3604)

*/

PRINT '-> DBCC TRACESTATUS (-1):'
DBCC TRACESTATUS (-1)
PRINT ''

PRINT '-> DBCC OPENTRAN (<database>):'

DECLARE @dbname sysname
DECLARE @tmpstr varchar(255)  
-- Note: won't work for 7.0/2K db's with Unicode names, 
-- but nvarchar won't work on 6.5.
DECLARE db_cursor cursor FOR 
SELECT name FROM master.dbo.sysdatabases 
WHERE status&32 + status&64 + status&128 + status&256 + status&512 = 0
  AND name NOT IN ('master', 'model', 'msdb', 'pubs', 'Northwind')  
OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @dbname
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN 
    SET @tmpstr = 'DBCC OPENTRAN (' + @dbname + ')'
    PRINT @tmpstr
    EXEC (@tmpstr)
    PRINT ''
  END
  FETCH NEXT FROM db_cursor INTO @dbname
END
CLOSE db_cursor 
DEALLOCATE db_cursor 
PRINT ''

PRINT '-> DBCC SQLPERF (THREADS)'
DBCC SQLPERF (THREADS)
PRINT ''

PRINT '-> DBCC SQLPERF (NETSTATS)'
DBCC SQLPERF (NETSTATS)
PRINT ''

PRINT '-> DBCC SQLPERF (IOSTATS)'
DBCC SQLPERF (IOSTATS)
PRINT ''

PRINT '-> DBCC SQLPERF (SPINLOCKSTATS)'
DBCC SQLPERF (SPINLOCKSTATS)
PRINT ''

-- This is potentially too large (was 80MB in one case) to capture by default. 
IF @bGetSyscacheobjects = 1
BEGIN
  PRINT '-> syscacheobjects'
  SELECT * FROM master.dbo.syscacheobjects
  PRINT ''
END

PRINT '-> DBCC MEMORYSTATUS'
DBCC MEMORYSTATUS
PRINT ''

PRINT '-> DBCC SQLPERF (UMSSTATS)'
DBCC SQLPERF (UMSSTATS)
PRINT ''

PRINT '-> DBCC SQLPERF (WAITSTATS)'
DBCC SQLPERF (WAITSTATS)
PRINT ''

PRINT '-> DBCC SQLPERF (LRUSTATS)'
DBCC SQLPERF (LRUSTATS)
PRINT ''

PRINT '-> sysperfinfo snapshot #1'
PRINT CONVERT (varchar, GETDATE(), 109)
SELECT * FROM master.dbo.sysperfinfo
WAITFOR DELAY '0:0:05'
PRINT '-> sysperfinfo snapshot #2'
PRINT CONVERT (varchar, GETDATE(), 109)
SELECT * FROM master.dbo.sysperfinfo
PRINT ''

PRINT '-> NET START'
EXEC master.dbo.xp_cmdshell 'NET START'
PRINT ''

DECLARE @IsFullTextInstalled int
PRINT '-> Full-text information'
PRINT '-> FULLTEXTSERVICEPROPERTY (IsFulltextInstalled)'
SET @IsFullTextInstalled = FULLTEXTSERVICEPROPERTY ('IsFulltextInstalled')
PRINT CASE @IsFullTextInstalled 
    WHEN 1 THEN '1 - Yes' 
    WHEN 0 THEN '0 - No' 
    ELSE 'Unknown'
  END
IF (@IsFullTextInstalled = 1)
BEGIN
  PRINT '-> FULLTEXTSERVICEPROPERTY (ResourceUsage)'
  PRINT CASE FULLTEXTSERVICEPROPERTY ('ResourceUsage')
      WHEN 0 THEN '0 - MSSearch not running'
      WHEN 1 THEN '1 - Background'
      WHEN 2 THEN '2 - Low'
      WHEN 3 THEN '3 - Normal'
      WHEN 4 THEN '4 - High'
      WHEN 5 THEN '5 - Highest'
      ELSE CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('ResourceUsage'))
    END

  PRINT '-> FULLTEXTSERVICEPROPERTY (ConnectTimeout)'
  PRINT CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('ConnectTimeout')) + ' sec'
  PRINT ''

  DECLARE @dbn varchar(31)
  DECLARE @cm varchar(8000)
  DECLARE db_cursor CURSOR FOR
  SELECT name FROM master.dbo.sysdatabases WHERE DATABASEPROPERTY (name, 'IsFulltextEnabled') = 1
  FOR READ ONLY
  IF 0 = @@ERROR
  BEGIN
    OPEN db_cursor
    IF 0 = @@ERROR
    BEGIN
      FETCH db_cursor INTO @dbn
      WHILE @@FETCH_STATUS <> -1 AND 0 = @@ERROR
      BEGIN
        SELECT @cm = '
USE ' + + @dbn + '
PRINT ''-> sp_help_fulltext_catalogs''
EXEC sp_help_fulltext_catalogs
PRINT ''-> sp_help_fulltext_tables''
EXEC sp_help_fulltext_tables
PRINT ''-> sp_help_fulltext_columns''
EXEC sp_help_fulltext_columns
PRINT ''-> Catalog properties''
SELECT name, FULLTEXTCATALOGPROPERTY (name, ''ItemCount'') AS ItemCount, 
  CONVERT (varchar, FULLTEXTCATALOGPROPERTY (name, ''IndexSize'')) + ''MB'' AS IndexSize, 
  FULLTEXTCATALOGPROPERTY (name, ''UniqueKeyCount'') AS [Unique word count] 
FROM sysfulltextcatalogs 
USE master'
        PRINT '-> Full text information for db [' + @dbn + ']'
        EXEC(@cm)
        FETCH db_cursor INTO @dbn
      END
      CLOSE db_cursor
    END
    DEALLOCATE db_cursor
  END
END
PRINT ''

PRINT '-> Relative time spent on I/O, CPU, and idle since server start'
SELECT @@CPU_BUSY AS [@@CPU_BUSY], @@IDLE AS [@@IDLE], @@IO_BUSY AS [@@IO_BUSY], 
  CONVERT (varchar(8), CONVERT (numeric (6, 4), (100.0 * @@CPU_BUSY / (@@CPU_BUSY + @@IDLE + @@IO_BUSY)))) + '%' AS Pct_CPU_BUSY, 
  CONVERT (varchar(8), CONVERT (numeric (6, 4), (100.0 * @@IDLE / (@@CPU_BUSY + @@IDLE + @@IO_BUSY)))) + '%' AS Pct_IDLE, 
  CONVERT (varchar(8), CONVERT (numeric (6, 4), (100.0 * @@IO_BUSY / (@@CPU_BUSY + @@IDLE + @@IO_BUSY)))) + '%' AS Pct_IO_BUSY
PRINT ''

PRINT '-> Misc network and I/O stats'
SELECT @@PACK_RECEIVED AS [@@PACK_RECEIVED], @@PACK_SENT AS [@@PACK_SENT], 
  @@PACKET_ERRORS AS [@@PACKET_ERRORS (network errors e.g. 17824)]
SELECT @@TOTAL_READ AS [@@TOTAL_READ], @@TOTAL_WRITE AS [@@TOTAL_WRITE], 
  @@TOTAL_ERRORS AS [@@TOTAL_ERRORS (disk read/write I/O errors)] 
---- Disabled -- On Win2k winmsd calls a MMC snapin and this doesn't
---- recognize the old winmsd cmd line params. 
-- PRINT ''
-- PRINT '======== Generating WinMSD Report'
-- EXEC master.dbo.xp_cmdshell 'c: & cd \ & winmsd -a'
-- GO
PRINT ''

PRINT '-> GETDATE()'
PRINT CONVERT (varchar, GETDATE(), 109)
PRINT ''
PRINT 'Done.'

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GOto rage. --?!?! too many similar messages
				begin
					raiserror(15064,-1,-1)
					return (1)
				end
		else if @type = 'F ' -- FK => no physical data storage.
				begin
					raiserror(15275,-1,-1)
					return (1)
				end
end

/*
**  Update usages if user specified to do so.
*/

if @updateusage = 'true'
	begin
		if @objname is null
			dbcc updateusage(0) with no_infomsgs
		else
			dbcc updateusage(0,@objname) with no_infomsgs
		print ' '
	end


set nocount on

/*
**  If @id is null, then we want summary data.
*/
/*	Space used calculated in the following way
**	@dbsize = Pages used
**	@bytesperpage = d.low (where d = master.dbo.spt_values) is
**	the # of bytes per page when d.type = 'E' and
**	d.number = 1.
**	Size = @dbsize * d.low / (1048576 (OR 1 MB))
*/
if @id is null
begin
	select @dbsize = sum(convert(dec(15),size))
		from dbo.sysfiles
		where (status & 64 = 0)

	select @logsize = sum(convert(dec(15),size))
		from dbo.sysfiles
		where (status & 64 <> 0)

	select @bytesperpage = low
		from master.dbo.spt_values
		where number = 1
			and type = 'E'
	select @pagesperMB = 1048576 / @bytesperpage

	select  database_name = db_name(),
		database_size =
			ltrim(str((@dbsize + @logsize) / @pagesperMB,15,2) + ' MB'),
		'unallocated space' =
			ltrim(str((@dbsize -
				(select sum(convert(dec(15),reserved))
					from sysindexes
						where indid in (0, 1, 255)
				)) / @pagesperMB,15,2)+ ' MB')

	print ' '
	/*
	**  Now calculate the summary data.
	**  reserved: sum(reserved) where indid in (0, 1, 255)
	*/
	insert into #spt_space (reserved)
		select sum(convert(dec(15),reserved))
			from sysindexes
				where indid in (0, 1, 255)

	/*
	** data: sum(dpages) where indid < 2
	**	+ sum(used) where indid = 255 (text)
	*/
	select @pages = sum(convert(dec(15),dpages))
			from sysindexes
				where indid < 2
	select @pages = @pages + isnull(sum(convert(dec(15),used)), 0)
		from sysindexes
			where indid = 255
	update #spt_space
		set data = @pages


	/* index: sum(used) where indid in (0, 1, 255) - data */
	update #spt_space
		set indexp = (select sum(convert(dec(15),used))
				from sysindexes
					where indid in (0, 1, 255))
			    - data

	/* unused: sum(reserved) - sum(used) where indid in (0, 1, 255) */
	update #spt_space
		set unused = reserved
				- (select sum(convert(dec(15),used))
					from sysindexes
						where indid in (0, 1, 255))

	select reserved = ltrim(str(reserved * d.low / 1024.,15,0) +
				' ' + 'KB'),
		data = ltrim(str(data * d.low / 1024.,15,0) +
				' ' + 'KB'),
		index_size = ltrim(str(indexp * d.low / 1024.,15,0) +
				' ' + 'KB'),
		unused = ltrim(str(unused * d.low / 1024.,15,0) +
				' ' + 'KB')
		from #spt_space, master.dbo.spt_values d
		where d.number = 1
			and d.type = 'E'
end

/*
**  We want a particular object.
*/
else
begin
	/*
	**  Now calculate the summary data.
	**  reserved: sum(reserved) where indid in (0, 1, 255)
	*/
	insert into #spt_space (reserved)
		select sum(reserved)
			from sysindexes
				where indid in (0, 1, 255)
					and id = @id

	/*
	** data: sum(dpages) where indid < 2
	**	+ sum(used) where indid = 255 (text)
	*/
	select @pages = sum(dpages)
			from sysindexes
				where indid < 2
					and id = @id
	select @pages = @pages + isnull(sum(used), 0)
		from sysindexes
			where indid = 255
				and id = @id
	update #spt_space
		set data = @pages


	/* index: sum(used) where indid in (0, 1, 255) - data */
	update #spt_space
		set indexp = (select sum(used)
				from sysindexes
					where indid in (0, 1, 255)
						and id = @id)
			    - data

	/* unused: sum(reserved) - sum(used) where indid in (0, 1, 255) */
	update #spt_space
		set unused = reserved
				- (select sum(used)
					from sysindexes
						where indid in (0, 1, 255)
							and id = @id)
	update #spt_space
		set rows = i.rows
			from sysindexes i
				where i.indid < 2
					and i.id = @id

	
	select name = object_name(@id),
		rows = convert(char(11), rows),
		reserved = str(reserved * d.low / 1024.,15,0),
		data = str(data * d.low / 1024.,15,0) ,
		index_size = str(indexp * d.low / 1024.,15,0),
		unused = str(unused * d.low / 1024.,15,0) 
	into #final_space
	from #spt_space, master.dbo.spt_values d
		where d.number = 1
			and d.type = 'E'
	
	select	name
	,	rows = dbo.uf_getSize(convert(varchar(30), convert(money, rows),1) )
	,	reserved = ltrim(dbo.uf_getSize(convert(varchar(30), convert(money, reserved),1) ) + ' ' + 'KB')
	,	data = ltrim(dbo.uf_getSize(convert(varchar(30), convert(money, data),1) ) + ' ' + 'KB')
	,	index_size = ltrim(dbo.uf_getSize(convert(varchar(30), convert(money, index_size),1) ) + ' ' + 'KB')
	,	unused = ltrim(dbo.uf_getSize(convert(varchar(30), convert(money, unused),1) ) + ' ' + 'KB')
	from #final_space

end

return (0) -- sp_spaceused





GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
