create procedure dbo.sp_who1 
  @spidpool varchar(500) = null,
  @status sysname = null,
  @loginame sysname = null,
  @command sysname = null,
  @dbname sysname = null, 
  @hostname sysname = null,
  @waittime int = null,
  @lastbatch datetime = null,
  @program sysname = null,
  @opentran int = null,
  @blocked bit = null
as

/*    Author: Richard Ding
**   Creation Date: 10/10/2004
**   Version: 1.0.0
*/
set nocount on
declare     -- search argument in the where clause
  @select varchar(2000),
  @SARG_spid varchar(20),
  @SARG_status varchar(40),
  @SARG_loginame varchar(150),
  @SARG_command varchar(40),
  @SARG_dbname varchar(150), 
  @SARG_hostname varchar(150),
  @SARG_waittime varchar(80),
  @SARG_lastbatch varchar(50),
  @SARG_program varchar(150),
  @SARG_opentran varchar(20),
  @SARG_blocked varchar(30),
  @SARG_all varchar(8000),
  @order_by_clause varchar(100),
  @header varchar(500),
  @where varchar(10), 
  @total_users int,
  @total_runnables int,
  --  define maximum column length for dynamic adjustment
  @max_spid varchar(5),
  @max_status varchar(5),
  @max_loginame varchar(5),
  @max_dbname varchar(5),
  @max_command varchar(5),
  @max_hostname varchar(5),
  @max_memusage varchar(5),
  @max_physical_io varchar(5),
  @max_program_name varchar(5),
  @max_cpu varchar(5),
  @max_opentran varchar(5),
  @max_blocked varchar(5),
  @max_waittime varchar(5),
  @max_lastwaittype varchar(5),
  @max_waitresource varchar(5),

--  this piece of T-SQL checks the validity of input spids pool
  @SARG_spidpool varchar(300), 
  @single_spid varchar(20), 
  @comma_position tinyint, 
  @error varchar(100),
  @spidpoollength int

set @spidpool = ltrim(rtrim(replace(@spidpool, ' ', '')))
set @spidpoollength = len(@spidpool)
set @SARG_spidpool = @spidpool

if @spidpool is not null  -- user provided one or more spids
  begin
    if patindex('%[^0-9 ,]%', @spidpool) = 0  -- clean pool, only numeric, space and comma allowed
      begin
        while @spidpoollength > 0
          begin
            set @comma_position = charindex(',', @spidpool)
            if @comma_position = 0			--  at the last spid
              set @comma_position = @spidpoollength+1
            set @single_spid = substring(@spidpool, 1, @comma_position-1)
            if convert(int, @single_spid) not between 0 and 32767
	            begin
                set @error = 'spid ' + @single_spid + ' out of range. Valid spids are integers between 0 
and 32767'
	              raiserror (@error, 16, 1)
          	    return (1)
	            end

            if charindex(',', @spidpool) = 0
              set @spidpoollength = 0
            else
              begin
                set @spidpool = substring(@spidpool, @comma_position+1, len(@spidpool)-
@comma_position)
                set @spidpoollength = len(@spidpool)
              end
          end
      end
    else 
	    begin
	      raiserror ('invalid character(s) in spid pool. Only numeric, space and comma allowed.', 
16, 1)
	      return (1)
	    end
  end

--  Make sure login name is existing
if (@loginame is not null)
  begin
    if not exists (select 1 from master.dbo.syslogins with (nolock) where name = @loginame)
      begin
		    raiserror(15007, -1, -1, @loginame)
		    return (1) 	
      end
  end

--  check if database is existing
if (@dbname is not null)
  begin
    if not exists (select name from master.dbo.sysdatabases with (nolock) where name = 
@dbname)
      begin
        raiserror (15010, -1, -1, @dbname)
        return (1)
      end
  end

if object_id('tempdb..##TmpSysprocesses') is null
  begin
    create table ##TmpSysprocesses  --  hold critical info and minimize performance hit on systable
    ( spid smallint,
      status nchar(30),
      loginame nchar(128),
      dbname nchar(128),
      command nchar(16),
      hostname nchar(128),
      memusg int,
      phys_io int,
      login_time datetime,
      last_batch datetime,
      program nchar(128),
      cpu int,
      blkBy smallint,
      open_tran smallint,
      waittype binary(2),
      waittime int,
      lastwaittype nchar(32),
      waitresource nchar(512) )
    create clustered index clust on ##TmpSysprocesses (spid)
--  create nonclustered index nclust on  ##TmpSysprocesses (status, loginame, dbname, command, hostname, last_batch, waittime, open_tran)
  end
else
  truncate table ##TmpSysprocesses

insert into ##TmpSysprocesses 
  select spid, status, loginame, db_name(dbid), cmd, hostname, memusage, physical_io, 
login_time, 
  last_batch, program_name, cpu, blocked, open_tran, waittype, waittime, lastwaittype, 
waitresource
  from master.dbo.sysprocesses with (nolock)

select 
  @max_spid = max(len(ltrim(str(spid)))),
  @max_status = ltrim(str(max(len(status)))),
  @max_loginame = ltrim(str(max(len(loginame)))),
  @max_dbname = ltrim(str(max(len(dbname)))),
  @max_command = ltrim(str(max(len(command)))),
  @max_hostname = ltrim(str(max(len(hostname)))),
  @max_memusage = max(len(ltrim(str(memusg)))),
  @max_physical_io = max(len(ltrim(str(phys_io)))),
  @max_program_name = ltrim(str(max(len(program)))),
  @max_cpu = max(len(ltrim(str(cpu)))),
  @max_opentran = max(len(ltrim(str(open_tran)))),
  @max_blocked = max(len(ltrim(str(blkBy)))),
  @max_waittime = max(len(ltrim(str(waittime)))),
  @max_lastwaittype = ltrim(str(max(len(lastwaittype)))),
  @max_waitresource = ltrim(str(max(len(waitresource)))) from ##TmpSysprocesses
select @total_users = count(spid) from ##TmpSysprocesses
select @total_runnables = count(spid) from ##TmpSysprocesses where status = 'runnable'
set @header = '***  sp_who1 at ' + substring(convert(varchar(30), getdate(), 9), 1, 20) + space(1) 
+ 
  substring(convert(varchar(30), getdate(), 9), 25, 2) + space(5) + 'Server: ' + 
upper(@@servername) + 
  space (5) + 'Total of spids: ' + ltrim(str(@total_users)) + space(5) + 
  'Total of runnables: ' + ltrim(str(@total_runnables)) + '  ***'+ char(10)

-- When blocking occurs
declare @block_flag bit
set @block_flag = 0
if (@blocked is not null)
begin
  if exists (select 1 from ##TmpSysprocesses where blkBy > 0)  -- there is blocking
    begin
      set @block_flag = 1
      if object_id ('tempdb..##TmpBlockingSpid') is null
        create table ##TmpBlockingSpid (spid int)
      else
        truncate table ##TmpBlockingSpid
      insert into ##TmpBlockingSpid    -- save head spid of blocking chain
        select distinct spid from ##TmpSysprocesses 
          where blkBy = 0 and spid in (select blkBy from ##TmpSysprocesses)
      print @header
      print ''
      print 'Head(s) of blocking chain is(are):' + char(13) + char(9) 
      select distinct spid from ##TmpBlockingSpid order by spid asc
      print ''
    end
end

select 
  @SARG_spidpool = case when @spidpool is null then '' 
    else ' and spid in (' + @SARG_spidpool + ')' end,
  @SARG_status = case when @status is null then '' 
    else ' and status = ''' + @status + '''' end,
  @SARG_loginame = case when @loginame is null then '' 
    else ' and loginame = ''' + @loginame + '''' end,
  @SARG_command = case when @command is null then '' 
    else ' and command = ''' + @command + '''' end,
  @SARG_dbname = case when @dbname is null then '' 
    else ' and dbname = ''' + @dbname + '''' end,
  @SARG_hostname = case when @hostname is null then '' 
    else ' and hostname = ''' + @hostname + '''' end,
  @SARG_waittime = case when @waittime is null then '' 
    else ' and waittype > 0x0000 and waittime > ' + ltrim(str(@waittime)) + '' end,
  @SARG_lastbatch = case when @lastbatch is null then '' 
    else ' and last_batch >= ''' + convert(varchar(30), @lastbatch) + '''' end,
  @SARG_program = case when @program is null then '' 
    else ' and program = ''' + @program + '''' end,
  @SARG_opentran = case when @opentran is null then '' 
    else ' and open_tran >= ' + ltrim(str(@opentran)) + '' end,
  @SARG_blocked = case when @blocked is null then '' 
    when @blocked = 0 then ' and blkBy = 0' 
    else ' and blkBy > 0' end
select @SARG_all = @SARG_spidpool + @SARG_status + @SARG_loginame + 
@SARG_command + 
                   @SARG_dbname + @SARG_hostname + @SARG_waittime + @SARG_lastbatch + 
                   @SARG_program + @SARG_opentran + @SARG_blocked

if len(@SARG_all) = 0
  set @where = ''
else 
  set @where = ' where '
select @SARG_all = substring(@SARG_all, 6, len(@SARG_all))
set @select = 'select 
  left(spid, ' + @max_spid + ') as ''SPID'', 
  left(status, ' + @max_status + ') AS ''status'', 
  left(loginame, ' + @max_loginame + ') AS ''loginame'', 
  left(dbname, ' + @max_dbname + ') AS ''dbname'', 
  left(command, ' + @max_command + ') as ''command'', 
  left(hostname, ' + @max_hostname + ') as ''hostname'',
  left(memusg, ' + @max_memusage + ') as ''memusg'',
  left(phys_io, ' + @max_physical_io + ') as ''phys_io'',
  left(substring(convert(varchar(25), login_time, 101), 1, 10) + 
    '' '' + convert(varchar(25), login_time, 8), 20) as ''login_time'', 
  left(substring(convert(varchar(25), last_batch, 101), 1, 10) + 
    '' '' + convert(varchar(25), last_batch, 8), 20) as ''last_batch'',
  left(spid, ' + @max_spid + ') as ''SPID'', 
  left(program, ' + @max_program_name + ') as ''program'',
  left(cpu, ' + @max_cpu + ') as ''cpu'',
  left(open_tran, ' + @max_opentran + ') as ''opentran'',
  left(blkBy, ' + @max_blocked + ') as ''blkBy'',
  left(waittime, ' + @max_waittime + ') as ''waittime'',
  left(lastwaittype, ' + @max_lastwaittype + ') as ''lastwaittype'',
  left(waitresource, ' + @max_waitresource + ') as ''waitresource'',
  left(spid, ' + @max_spid + ') as ''SPID'' from ##TmpSysprocesses ' 
set @order_by_clause = ' order by dbname asc, loginame asc, status asc, command asc'
print ''
if @block_flag <> 1
  print @header
exec (@select + @where + @SARG_all + @order_by_clause)
return (0)


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
