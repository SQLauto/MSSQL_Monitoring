/*----------------------------------------------------
    Date    : 2008-05-06
    Note    : Master DB 프로시저
    No.     :
*----------------------------------------------------*/
use master
go

-- ============================================================
-- 4. 2000 Master 데이터베이스 function 생성
-- 
-- =============================================================
create function dbo.uf_getSize(@size varchar(100))
returns varchar(100)
as 
begin
	declare @charindex int, @sp_name varchar(100)
	select @charindex = charindex('.', @size)
	if @charindex = 0 
		set @sp_name = @size
	else
		select @sp_name = substring(@size, 1, @charindex-1)
	return (@sp_name)
end
go

/*
blockinglocks
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
*/
create proc dbo.sp_blockinglocks
@exec_mode int  =1
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

		select 
		l1.request_session_id
		,l1.resource_type 
		,11.resource_subtype
		,l1.resource_description
		,l1.request_mode
		,l1.request_type
		,l1.request_status
		from sys.dm_tran_locks l1 with(nolock)
		where l1.resource_type != 'DATABASE' --DB lock 제외!
		order by l1.resource_description , l1.request_status

		SET NOCOUNT OFF
end
go

/*
sp_who3(SQL2005)
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
지난 2초간 가장 CPU를 많이사용한 프로세스를 보여준다.
*/

CREATE proc sp_who3
@res_count  int = 15
,@delay_time datetime  = '00:00:02'
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET LOCK_TIMEOUT 10000
	
	  ----------------------------------------------------------------
	  -- insert sys.dm_exec_requests into temp table !
	  ----------------------------------------------------------------
		select 
		session_id
		,sql_handle
		,cpu_time
		,(writes + reads) as physical_io into #tmp_requests 
		from sys.dm_exec_requests with(nolock) 
		
		----------------------------------------------------------------
	  -- delay with parameter
	  ----------------------------------------------------------------
		WAITFOR DELAY @delay_time
		
		
		----------------------------------------------------------------
	  -- find 
	  ----------------------------------------------------------------
		
		select
		t1.text as sql_string
		,raw.session_id
		,raw.cpu_gap as 'cpu변화'
		,raw.cpu_time
		,raw.physical_io
		,raw.host_name
		,raw.start_time
		,raw.program_name
		,raw.login_name
		from (
			----------------------------------------------------------------
	  	-- compare with temptable (calc cpu_time) or physical_io
	  	----------------------------------------------------------------
			select top(@res_count) 
			req1.sql_handle
			,req1.session_id
			,(req1.cpu_time - req2.cpu_time) as 'cpu_gap'
			, req1.cpu_time
			,(req1.reads + req1.writes) as 'physical_io'
			,session.host_name
			,req1.start_time
			,session.program_name
			,session.login_name 
			from sys.dm_exec_requests req1 with(nolock)
			inner join sys.dm_exec_sessions session with(nolock) on req1.session_id = session.session_id
			inner join #tmp_requests req2 with(nolock) on ( req1.session_id = req2.session_id and  req1.sql_handle = req2.sql_handle)
			where req1.session_id > 64
			order by 'cpu_gap' desc , req1.cpu_time desc 
		) raw 
		cross apply sys.dm_exec_sql_text(raw.sql_handle) as t1
		
		
		SET NOCOUNT OFF
end		 
go

create procedure dbo.sp_blocker_pss80 (@latch int = 0, @fast int = 1, @appname sysname='PSSDIAG')  
as   
--version 16SP3  
if is_member('sysadmin')=0   
begin  
  print 'Must be a member of the sysadmin group in order to run this procedure'  
  return  
end  
  
set nocount on  
SET LANGUAGE 'us_english'  
declare @spid varchar(6)  
declare @blocked varchar(6)  
declare @time datetime  
declare @time2 datetime  
declare @dbname nvarchar(128)  
declare @status sql_variant  
declare @useraccess sql_variant  
  
set @time = getdate()  
declare @probclients table(spid smallint, ecid smallint, blocked smallint, waittype binary(2), dbid smallint,  
   ignore_app tinyint, primary key (blocked, spid, ecid))  
insert @probclients select spid, ecid, blocked, waittype, dbid,  
   case when convert(varchar(128),hostname) = @appname then 1 else 0 end  
   from sysprocesses where blocked!=0 or waittype != 0x0000  
  
if exists (select spid from @probclients where ignore_app != 1 or waittype != 0x020B)  
begin  
   set @time2 = getdate()  
   print ''  
   print '8.2 Start time: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,@time2))  
  
   insert @probclients select distinct blocked, 0, 0, 0x0000, 0, 0 from @probclients  
      where blocked not in (select spid from @probclients) and blocked != 0  
  
   if (@fast = 1)  
   begin  
      print ''  
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)  
  
      select spid, status, blocked, open_tran, waitresource, waittype,   
         waittime, cmd, lastwaittype, cpu, physical_io,  
         memusage, last_batch=convert(varchar(26), last_batch,121),  
         login_time=convert(varchar(26), login_time,121),net_address,  
         net_library, dbid, ecid, kpid, hostname, hostprocess,  
         loginame, program_name, nt_domain, nt_username, uid, sid,  
         sql_handle, stmt_start, stmt_end  
      from master..sysprocesses  
      where blocked!=0 or waittype != 0x0000  
         or spid in (select blocked from @probclients where blocked != 0)  
         or spid in (select spid from @probclients where blocked != 0)  
  
      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate()))   
  
      print ''  
      print 'SYSPROC FIRST PASS'  
      select spid, ecid, waittype from @probclients where waittype != 0x0000  
  
      if exists(select blocked from @probclients where blocked != 0)  
      begin  
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)  
         print ''  
         print 'SPIDs at the head of blocking chains'  
         select spid from @probclients  
            where blocked = 0 and spid in (select blocked from @probclients where spid != 0)  
         if @latch = 0  
         begin  
            print 'SYSLOCKINFO'  
            select @time2 = getdate()  
  
            select spid = convert (smallint, req_spid),  
               ecid = convert (smallint, req_ecid),  
               rsc_dbid As dbid,  
               rsc_objid As ObjId,  
               rsc_indid As IndId,  
               Type = case rsc_type when 1 then 'NUL'  
                                    when 2 then 'DB'  
                                    when 3 then 'FIL'  
                                    when 4 then 'IDX'  
                                    when 5 then 'TAB'  
                                    when 6 then 'PAG'  
                                    when 7 then 'KEY'  
                                    when 8 then 'EXT'  
                                    when 9 then 'RID'  
                                    when 10 then 'APP' end,  
               Resource = substring (rsc_text, 1, 16),  
               Mode = case req_mode + 1 when 1 then NULL  
                                        when 2 then 'Sch-S'  
                                        when 3 then 'Sch-M'  
                                        when 4 then 'S'  
                                        when 5 then 'U'  
                                        when 6 then 'X'  
                                   when 7 then 'IS'  
                                        when 8 then 'IU'  
                                        when 9 then 'IX'  
                                        when 10 then 'SIU'  
                                        when 11 then 'SIX'  
                                        when 12 then 'UIX'  
                                        when 13 then 'BU'  
                                        when 14 then 'RangeS-S'  
                                        when 15 then 'RangeS-U'  
                                        when 16 then 'RangeIn-Null'  
                                        when 17 then 'RangeIn-S'  
                                        when 18 then 'RangeIn-U'  
                                        when 19 then 'RangeIn-X'  
                                        when 20 then 'RangeX-S'  
                                        when 21 then 'RangeX-U'  
                                        when 22 then 'RangeX-X'end,  
               Status = case req_status when 1 then 'GRANT'  
                                        when 2 then 'CNVT'  
                                        when 3 then 'WAIT' end,  
               req_transactionID As TransID, req_transactionUOW As TransUOW  
            from master.dbo.syslockinfo s,  
               @probclients p  
            where p.spid = s.req_spid  
  
            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate()))   
         end -- latch not set  
      end  
      else  
         print 'No blocking via locks at ' + convert(varchar(26), @time, 121)  
      print ''  
   end  -- fast set  
  
   else    
   begin  -- Fast not set  
      print ''  
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)  
  
      select spid, status, blocked, open_tran, waitresource, waittype,   
         waittime, cmd, lastwaittype, cpu, physical_io,  
         memusage, last_batch=convert(varchar(26), last_batch,121),  
         login_time=convert(varchar(26), login_time,121),net_address,  
         net_library, dbid, ecid, kpid, hostname, hostprocess,  
         loginame, program_name, nt_domain, nt_username, uid, sid,  
         sql_handle, stmt_start, stmt_end  
      from master..sysprocesses  
  
      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate()))   
  
      print ''  
      print 'SYSPROC FIRST PASS'  
      select spid, ecid, waittype from @probclients where waittype != 0x0000  
  
      if exists(select blocked from @probclients where blocked != 0)  
      begin  
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)  
         print ''  
         print 'SPIDs at the head of blocking chains'  
         select spid from @probclients  
         where blocked = 0 and spid in (select blocked from @probclients where spid != 0)  
         if @latch = 0  
         begin  
            print 'SYSLOCKINFO'  
            select @time2 = getdate()  
  
            select spid = convert (smallint, req_spid),  
               ecid = convert (smallint, req_ecid),  
               rsc_dbid As dbid,  
               rsc_objid As ObjId,  
               rsc_indid As IndId,  
               Type = case rsc_type when 1 then 'NUL'  
                                    when 2 then 'DB'  
                                    when 3 then 'FIL'  
                                    when 4 then 'IDX'  
                                    when 5 then 'TAB'  
                                    when 6 then 'PAG'  
                                    when 7 then 'KEY'  
                                    when 8 then 'EXT'  
                                    when 9 then 'RID'  
                                    when 10 then 'APP' end,  
               Resource = substring (rsc_text, 1, 16),  
               Mode = case req_mode + 1 when 1 then NULL  
                                        when 2 then 'Sch-S'  
                                        when 3 then 'Sch-M'  
                                        when 4 then 'S'  
                                        when 5 then 'U'  
                                        when 6 then 'X'  
                                        when 7 then 'IS'  
                                        when 8 then 'IU'  
                                        when 9 then 'IX'  
                                        when 10 then 'SIU'  
                                        when 11 then 'SIX'  
                                        when 12 then 'UIX'  
                                        when 13 then 'BU'  
                                        when 14 then 'RangeS-S'  
                                        when 15 then 'RangeS-U'  
                                        when 16 then 'RangeIn-Null'  
                                        when 17 then 'RangeIn-S'  
                                        when 18 then 'RangeIn-U'  
                                        when 19 then 'RangeIn-X'  
                                        when 20 then 'RangeX-S'  
                                        when 21 then 'RangeX-U'  
                                        when 22 then 'RangeX-X'end,  
               Status = case req_status when 1 then 'GRANT'  
                                        when 2 then 'CNVT'  
                                        when 3 then 'WAIT' end,  
               req_transactionID As TransID, req_transactionUOW As TransUOW  
            from master.dbo.syslockinfo  
  
            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate()))   
         end -- latch not set  
      end  
      else  
        print 'No blocking via locks at ' + convert(varchar(26), @time, 121)  
      print ''  
   end -- Fast not set  
  
   print 'DBCC SQLPERF(WAITSTATS)'  
   dbcc sqlperf(waitstats)  
  
   Print ''  
   Print '*********************************************************************'  
   Print 'Print out DBCC Input buffer for all blocked or blocking spids.'  
   Print '*********************************************************************'  
  
   declare ibuffer cursor fast_forward for  
   select distinct cast (spid as varchar(6)) as spid  
   from @probclients  
   where (spid <> @@spid) and   
      ((blocked!=0 or (waittype != 0x0000 and ignore_app = 0))  
      or spid in (select blocked from @probclients where blocked != 0))  
   open ibuffer  
   fetch next from ibuffer into @spid  
   while (@@fetch_status != -1)  
   begin  
      print ''  
      print 'DBCC INPUTBUFFER FOR SPID ' + @spid  
      exec ('dbcc inputbuffer (' + @spid + ')')  
  
      fetch next from ibuffer into @spid  
   end  
   deallocate ibuffer  
  
   Print ''  
   Print '*******************************************************************************'  
   Print 'Print out DBCC OPENTRAN for active databases for all blocked or blocking spids.'  
   Print '*******************************************************************************'  
   declare ibuffer cursor fast_forward for  
   select distinct cast (dbid as varchar(6)) from @probclients  
   where dbid != 0  
   open ibuffer  
   fetch next from ibuffer into @spid  
   while (@@fetch_status != -1)  
   begin  
      print ''  
      set @dbname = db_name(@spid)  
      set @status = DATABASEPROPERTYEX(@dbname,'Status')  
      set @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')  
      print 'DBCC OPENTRAN FOR DBID ' + @spid + ' ['+ @dbname + ']'  
      if @Status = N'ONLINE' and @UserAccess != N'SINGLE_USER'  
         dbcc opentran(@dbname)  
      else  
         print 'Skipped: Status=' + convert(nvarchar(128),@status)  
            + ' UserAccess=' + convert(nvarchar(128),@useraccess)  
  
      print ''  
      if @spid = '2' select @blocked = 'Y'  
      fetch next from ibuffer into @spid  
   end  
   deallocate ibuffer  
   if @blocked != 'Y'   
   begin  
      print ''  
      print 'DBCC OPENTRAN FOR DBID  2 [tempdb]'  
      dbcc opentran ('tempdb')  
   end  
  
   print 'End time: ' + convert(varchar(26), getdate(), 121)  
end -- All  
else  
  print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' '   
     + convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)')  
  
go
CREATE PROC SP_BLOCKING_SESSIONS
AS 

SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ COMMITTED  

select 		r.session_id
		,status
		,isnull(db_name(qt.dbid), qt.dbid) as db_nm
		,isnull(object_name(qt.objectid), qt.objectid) as object_nm
		,r.cpu_time
		,r.total_elapsed_time
		,r.logical_reads
		,r.writes
		,r.reads
		,r.last_wait_type
		,r.wait_time
		,r.blocking_session_id as blocking
		,substring(qt.text,r.statement_start_offset/2, 
			(case when r.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else r.statement_end_offset end - r.statement_start_offset)/2) 
		as query_text   --- this is the statement executing right now
		--,r.scheduler_id
from sys.dm_exec_requests r
cross apply sys.dm_exec_sql_text(sql_handle) as qt
inner join (select blocking_session_id from sys.dm_exec_requests where blocking_session_id > 0) r2 on r.session_id = r2.blocking_session_id
where r.session_id > 50
order by r.session_id

SET NOCOUNT OFF
go

/*
blockinglocks
작성일 : 2007-08-06 
작성자 : 윤태진
파라미터 : 
*/
CREATE proc dbo.sp_blockinglocks
@exec_mode int  =1
as
begin
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	select 
l1.request_session_id
,db.name
,session.host_name
,session.program_name
,session.login_name
,l1.resource_type 
,11.resource_subtype
,l1.resource_description
,l1.Resource_associated_entity_id
,l1.request_mode
,l1.request_type
,l1.request_status
from sys.dm_tran_locks l1 with(nolock) 
inner join sys.dm_tran_locks l2 with(nolock) on ( l1.resource_database_id = l2.resource_database_id and l1.resource_associated_entity_id = l2.resource_associated_entity_id)
inner join master..sysdatabases db with(nolock) on l1.resource_database_id = db.dbid
inner join sys.dm_exec_sessions session with(nolock) on session.session_id = l1.request_session_id
where l1.resource_type != 'DATABASE' --DB lock 제외!
and l1.request_status <> l2.request_status
and l1.request_session_id <> l2.request_session_id
order by l1.resource_description , l1.request_status


		SET NOCOUNT OFF
end
go
create procedure sp_blockinglocks2   
as  
set nocount on  
 select  DISTINCT convert (smallint, l1.req_spid) As spid,   
  l1.rsc_dbid As dbid,   
  l1.rsc_objid As ObjId,  
  l1.rsc_indid As IndId,  
  substring (v.name, 1, 4) As Type,  
  substring (l1.rsc_text, 1, 16) as Resource,  
  substring (u.name, 1, 8) As Mode,  
  substring (x.name, 1, 5) As Status  
 from  master.dbo.syslockinfo l1,  
  master.dbo.syslockinfo l2,  
  master.dbo.spt_values v,  
  master.dbo.spt_values x,  
  master.dbo.spt_values u  
 where          l1.rsc_type = v.number  
   and v.type = 'LR'  
   and l1.req_status = x.number  
   and x.type = 'LS'  
   and l1.req_mode + 1 = u.number  
   and u.type = 'L'  
   and l1.rsc_type <>2 /* not a DB lock */  
   and l1.rsc_dbid = l2.rsc_dbid  
   and l1.rsc_bin = l2.rsc_bin  
                        and l1.rsc_objid = l2.rsc_objid   
   and l1.rsc_indid = l2.rsc_indid   
   and l1.req_spid <> l2.req_spid  
   and l1.req_status <> l2.req_status  
   --and (l1.req_spid in (select blocked from master..sysprocesses)  
   -- or l2.req_spid in (select blocked from master..sysprocesses))  
 order by substring (l1.rsc_text, 1, 16), substring (x.name, 1, 5)   
return (0) -- sp_blockinglocks 
go
CREATE PROC dbo.sp_code_runner 
    @StartCmd nvarchar(4000)='/?', 
    @StartTime char(8)=NULL, 
    @StopCondition nvarchar(4000)=NULL,
    @StopMessage nvarchar(4000)='Stop condition met.', 
    @IterationTime char(8)=NULL, 
    @Duration char(8)=NULL, 
    @StopCmd nvarchar(4000)=NULL, 
    @PollingInterval char(8)='00:00:05', 
    @PauseBetweenRuns char(8)=NULL,
    @OutputDir sysname=NULL, 
    @OutputFileMask sysname=NULL, 
    @NumFiles int=16
AS
SET NOCOUNT ON

IF @StartCmd='/?' GOTO Help

-- Do some minimal parm checking
IF COALESCE(@Duration, @StopCondition) IS NULL BEGIN
  RAISERROR('You must supply either the @Duration or the @StopCondition parameter.',16,10)
  RETURN -1
END
IF @OutputFileMask='*' BEGIN
  RAISERROR('You may not specify an empty file mask.',16,10)
  RETURN -1
END
IF (@OutputDir IS NOT NULL) AND (@OutputFileMask IS NULL) BEGIN
  RAISERROR('You must supply a file mask when supplying a directory.',16,10)
  RETURN -1
END

-- Wait until the start time if there is one
IF @StartTime IS NOT NULL
  WAITFOR TIME @StartTime

-- Declare some variables and assign initial values
DECLARE @Stop int, @i int, @EndTime datetime, @CurDate datetime, @CurDateStr varchar(25),
        @FName sysname, @DelCmd varchar(255), @OutputDirCmd varchar(255), @SCmd nvarchar(4000),
        @IterationDateTime datetime
SET @CurDate=getdate()
SET @EndTime=@CurDate+@Duration
SET @Stop=CASE WHEN @CurDate >= @EndTime THEN 1 ELSE 0 END  -- @Duration of 00:00:00, perhaps?
SET @i=0
SET @StopCondition='IF ('+@StopCondition+') RAISERROR('''+@StopMessage+''',11,1)'

IF @OutputDir IS NOT NULL BEGIN -- If we're going to generate file names, delete any old ones
  IF RIGHT(@OutputDir,1)<>'\' SET @OutputDir=@OutputDir+'\'
  SET @DelCmd='DEL '+@OutputDir+@OutputFileMask
--  EXEC xp_cmdshell @DelCmd, no_output -- Delete all files matching the mask
  SET @OutputDirCmd='DIR '+@OutputDir+@OutputFileMask+' /B /ON' -- Prepare for Dir listing (below)
END

--IF (@Stop<>1) AND (@StopCondition IS NOT NULL)  -- Check the stop condition - don't start if it's met
--  EXEC @Stop=sp_executesql @StopCondition
WHILE (@Stop=0) BEGIN

  IF @OutputDir IS NOT NULL BEGIN -- Gen a file name using the current date and time
    SET @CurDateStr=CONVERT(CHAR(8),getdate(),112) + REPLACE(CONVERT(varchar(15),getdate(),114),':','')
    SET @FName=REPLACE(@OutputFileMask,'*',@CurDateStr)
		IF (@@MICROSOFTVERSION >= 134217922 /* SS2K RTM */) BEGIN 
			DECLARE @p int
			SET @p=CHARINDEX('.trc',@FName)
			IF (@p<>0) SET @FName=LEFT(@FName,@p-1)	
    END
    SET @SCmd=@StartCmd+', @FileName='''+CAST(@OutputDir+@FName as nvarchar(255))+''''
  END ELSE SET @SCmd=@StartCmd

  EXEC sp_executesql @SCmd -- Execute the start command

  SET @IterationDateTime=getdate()+ISNULL(@IterationTime,'23:59:59.999')
  WHILE (@Stop=0) AND (getdate()<@IterationDateTime) BEGIN

--	  IF @IterationTime IS NOT NULL -- Do the per iteration pause
--	    WAITFOR DELAY @IterationTime

/*
	-- Special handling for .trc files
	IF (CHARINDEX('.TRC',@OutputFileMask)<>0) BEGIN
		--Cab and delete inactive trace files -- we won't be able to open active files
		SET @DelCmd='for %d in ('+@OutputDir+'*.trc) do '+@OutputDir+'compress '+@OutputDir+' %d'
    SELECT @DelCmd
		EXEC master..xp_cmdshell @DelCmd, no_output
	END
*/

	  IF @PollingInterval IS NOT NULL -- Do polling interval delay
      WAITFOR DELAY @PollingInterval 
	
	  SET @Stop=CASE WHEN getdate() >= @EndTime THEN 1 ELSE 0 END -- Check the duration
	
	  IF (@Stop<>1) AND (@StopCondition IS NOT NULL) -- Check the stop condition
	    EXEC @Stop=sp_executesql @StopCondition
	END
  IF @StopCmd IS NOT NULL -- Execute the stop command if there is one
    EXEC sp_executesql @StopCmd
	
  SET @i=@i+1
  IF (@OutputDir IS NOT NULL) AND (@i>@NumFiles) BEGIN -- Get rid of extra files

    CREATE TABLE #files (fname varchar(255) NULL)

    INSERT #files
    EXEC master..xp_cmdshell @OutputDirCmd

    SELECT TOP 1 @DelCmd='DEL '+@OutputDir+fname FROM #files WHERE fname IS NOT NULL ORDER BY fname
    IF @@ROWCOUNT<>0
      EXEC master..xp_cmdshell @DelCmd, no_output

    DROP TABLE #files

  END
	  IF @PauseBetweenRuns IS NOT NULL -- Do pause between runs delay
      WAITFOR DELAY @PauseBetweenRuns
END
RETURN 0

Help:
DECLARE @crlf char(2), @tabc char(1)
SET @crlf=char(13)+char(10)
SET @tabc=char(9)
PRINT 'Procedure: sp_code_runner'
PRINT @crlf+'Purpose: runs a specified TSQL command batch or stored procedure repetitively for a specified period of time'
PRINT @crlf+'Parameters:'
PRINT @tabc+'@StartCmd           nvarchar(4000)   default: (none)       -- the TSQL command or procedure to start'
PRINT @tabc+'@StartTime          char(8)          default: NULL         -- the time to begin processing'
PRINT @tabc+'@StopCondition      nvarchar(4000)   default: NULL         -- the condition to check to determine whether to stop @StartCmd'
PRINT @tabc+'@StopMessage        nvarchar(4000)   default: NULL         -- the message to display when the stop condition is met'
PRINT @tabc+'@IterationTime      char(8)          default: NULL         -- the time that should elapse between iterations'
PRINT @tabc+'@PollingInterval    char(8)          default: 00:00:10     -- the time to pause between checks of the @StopCondition'
PRINT @tabc+'@Duration           char(8)          default: NULL         -- the total amount of time @StartCmd should run'
PRINT @tabc+'@StopCmd            nvarchar(4000)   default: NULL         -- the TSQL command or procedure to run to stop @StartCmd'
PRINT @tabc+'@OutputDir          sysname          default: NULL         -- the target directory for the output file (if applicable -- proc must support @FileName parameter)'
PRINT @tabc+'@OutputFileMask     sysname          default: NULL         -- the filemask for output files (if applicable -- proc must support @FileName parameter)'
PRINT @tabc+'@NumFiles           int              default: 16           -- the number of output files to retain (if applicable -- proc must support @FileName parameter)'
PRINT @crlf+'Examples: '
PRINT @tabc+'EXEC sp_code_runner @StartCmd=N''EXEC sp_trace ''''ON'''''','
PRINT @tabc+'@StopCondition=N''OBJECT_ID(''''tempdb..stoptab'''') IS NOT NULL'','
PRINT @tabc+'@StopMessage=N''Trace stopped'', @IterationTime=''00:30:00'','
PRINT @tabc+'@StopCmd=N''EXEC sp_trace ''''OFF'''''','
PRINT @tabc+'@OutputDir=''c:\temp'',@OutputFileMask=''sp_trace*.trc'', @NumFiles=16'
PRINT @crlf+@tabc+'EXEC sp_code_runner @StartCmd=N''EXEC sp_trace ''''ON'''''','
PRINT       @tabc+'@IterationTime=''00:30:00'', @Duration=''12:00:00'','
PRINT       @tabc+'@StopCmd=N''EXEC sp_trace ''''OFF'''''','
PRINT       @tabc+'@OutputDir=''c:\temp'',@OutputFileMask=''sp_trace*.trc'', @NumFiles=10'
PRINT @crlf+@tabc+'EXEC sp_code_runner @StartCmd=N''EXEC sp_blocker_pss70'','
PRINT       @tabc+'@StopCondition=N''EXISTS(SELECT waittime FROM master..sysprocesses WHERE waittime>60000 AND blocked>0)'','
PRINT       @tabc+'@StopMessage=''Longterm block detected'','
PRINT       @tabc+'@IterationTime=''00:05:00'', @Duration=''12:00:00'''
PRINT @crlf+@tabc+'EXEC sp_code_runner @StartCmd=N''EXEC sp_blocker_pss70'','
PRINT       @tabc+'@StartTime=''00:22:00'', @IterationTime=''00:05:00'', @Duration=''12:00:00'''
RETURN 0

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'sp_current_recompile' 
	   AND 	  type = 'P')
    DROP PROCEDURE  sp_current_recompile
*/

/*************************************************************************  
* 프로시저명  : dbo.sp_current_recompile 
* 작성정보    : 2007-10-30 
* 관련페이지  :  
* 내용        : 프로시저의 리컴파일 수치
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE sp_current_recompile  
as  
set nocount on  
select top 100  
 plan_generation_num,  
 execution_count,  
 isnull(db_name(dbid), dbid),  
 isnull(object_name(objectid), objectid),  
 substring(qt.text,A.statement_start_offset/2,   
   (case when A.statement_end_offset = -1   
   then len(convert(nvarchar(max), qt.text)) * 2   
   else A.statement_end_offset end - A.statement_start_offset)/2)   
  as executing_query_text   --- this is the statement executing right now  
from sys.dm_exec_query_stats a  
 Cross apply sys.dm_exec_sql_text(sql_handle) as QT  
where plan_generation_num >1  
order by plan_generation_num desc  
  
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROC dbo.sp_exec_status
	@sp_name varchar(150)  
AS  
 SET NOCOUNT ON  
 SET QUERY_GOVERNOR_COST_LIMIT 0  
 SELECT @sp_name
 SELECT 
	plan_generation_num, 
	creation_time,  
	last_execution_time,
	execution_count,
	total_worker_time,
	last_worker_time,
	min_worker_time,
	max_worker_time,
	total_worker_time / execution_count as avg_worker_time,
	total_logical_writes,
	last_logical_writes,
	min_logical_writes,
	max_logical_writes,
	total_logical_reads,
	last_logical_reads,
	min_logical_reads,
	max_logical_reads,
	total_logical_reads / execution_count as avg_logical_reads,
	total_elapsed_time,
	last_elapsed_time,
	min_elapsed_time,
	max_elapsed_time,
	substring(qt.text,r.statement_start_offset/2, 
		(case when r.statement_end_offset = -1 
		then len(convert(nvarchar(max), qt.text)) * 2 
		else r.statement_end_offset end - r.statement_start_offset)/2) 
	as query_text   --- this is the statement executing right now
FROM SYS.DM_EXEC_QUERY_STATS r CROSS APPLY SYS.DM_EXEC_SQL_TEXT (PLAN_HANDLE) QT WHERE OBJECTID = OBJECT_ID(@sp_name)  
/*
declare @exe_cnt numeric(30, 5)
declare @total_worker_time numeric(30, 5)
	,@total_logical_writes numeric(30, 5)
	,@total_logical_reads numeric(30, 5)
	,@total_elapsed_time numeric(30, 5)
 SELECT 
	@exe_cnt = sum(execution_count),
	@total_worker_time = sum(total_worker_time),
	@total_logical_writes = sum(total_logical_writes),
	@total_logical_reads = sum(total_logical_reads),
	@total_elapsed_time = sum(total_elapsed_time)
FROM SYS.DM_EXEC_QUERY_STATS r CROSS APPLY SYS.DM_EXEC_SQL_TEXT (PLAN_HANDLE) QT WHERE OBJECTID = OBJECT_ID(@sp_name)  


select	@exe_cnt / sum(execution_count) as execution,
	@total_worker_time / sum(total_worker_time) as total_worker_time, 
	@total_logical_reads / sum(total_logical_reads) as total_logical_reads, 
	@total_logical_writes / sum(total_logical_writes) as total_logical_writes, 
	@total_elapsed_time / sum(total_elapsed_time) as total_elapsed_time 
from sys.dm_exec_query_stats
*/
SET NOCOUNT OFF  
go

CREATE PROC [DBO].[SP_GET_WAITSTATS] 
	(@REPORT_FORMAT VARCHAR(20)='ALL', 
	@REPORT_ORDER VARCHAR(20)='RESOURCE') 
AS 

-- THIS STORED PROCEDURE IS PROVIDED "AS IS" WITH NO WARRANTIES, AND 
-- CONFERS NO RIGHTS. 
-- USE OF INCLUDED SCRIPT SAMPLES ARE SUBJECT TO THE TERMS SPECIFIED AT 
-- HTTP://WWW.MICROSOFT.COM/INFO/CPYRIGHT.HTM 
--
-- THIS PROC WILL CREATE WAITSTATS REPORT LISTING WAIT TYPES BY 
-- PERCENTAGE. 
-- (1) TOTAL WAIT TIME IS THE SUM OF RESOURCE & SIGNAL WAITS, 
-- 	@REPORT_FORMAT='ALL' REPORTS RESOURCE & SIGNAL 
-- (2) BASICS OF EXECUTION MODEL (SIMPLIFIED) 
-- 	A. SPID IS RUNNING THEN NEEDS UNAVAILABLE RESOURCE, MOVES TO 
-- 	RESOURCE WAIT LIST AT TIME T0 
-- 	B. A SIGNAL INDICATES RESOURCE AVAILABLE, SPID MOVES TO 
-- 	RUNNABLE QUEUE AT TIME T1 
-- 	C. SPID AWAITS RUNNING STATUS UNTIL T2 AS CPU WORKS ITS WAY 
-- 	THROUGH RUNNABLE QUEUE IN ORDER OF ARRIVAL 
-- (3) RESOURCE WAIT TIME IS THE ACTUAL TIME WAITING FOR THE 
-- 	RESOURCE TO BE AVAILABLE, T1-T0 
-- (4) SIGNAL WAIT TIME IS THE TIME IT TAKES FROM THE POINT THE 
-- 	RESOURCE IS AVAILABLE (T1) 
-- 	TO THE POINT IN WHICH THE PROCESS IS RUNNING AGAIN AT T2.
-- 	THUS, SIGNAL WAITS ARE T2-T1 
-- (5) KEY QUESTIONS: ARE RESOURCE AND SIGNAL TIME SIGNIFICANT? 
-- 	A. HIGHEST WAITS INDICATE THE BOTTLENECK YOU NEED TO SOLVE 
-- 	FOR SCALABILITY 
-- 	B. GENERALLY IF YOU HAVE LOW% SIGNAL WAITS, THE CPU IS 
-- 	HANDLING THE WORKLOAD E.G. SPIDS SPEND MOVE THROUGH 
-- 	RUNNABLE QUEUE QUICKLY 
-- 	C. HIGH % SIGNAL WAITS INDICATES CPU CAN'T KEEP UP, 
-- 	SIGNIFICANT TIME FOR SPIDS TO MOVE UP THE RUNNABLE QUEUE 
-- 	TO REACH RUNNING STATUS 
-- (6) THIS PROC CAN BE RUN WHEN TRACK_WAITSTATS IS EXECUTING 
-- 
-- REVISION 4/19/2005 
-- (1) ADD COMPUTATION FOR CPU RESOURCE WAITS = SUM(SIGNAL WAITS / TOTAL WAITS) 
-- (2) ADD @REPORT_ORDER PARM TO ALLOW SORTING BY RESOURCE, SIGNAL OR TOTAL WAITS 

SET NOCOUNT ON 

DECLARE 	@NOW DATETIME, 
		@TOTALWAITCOUNTS NUMERIC(20,1),
		@TOTALWAIT NUMERIC(20,1), 
		@TOTALSIGNALWAIT NUMERIC(20,1), 
		@TOTALRESOURCEWAIT NUMERIC(20,1), 
		@ENDTIME DATETIME,
		@BEGINTIME DATETIME, 
		@HR INT, 
		@MIN INT, 
		@SEC INT 

/*IF NOT EXISTS 	(SELECT 
			1 
		FROM 
			SYSOBJECTS 
		WHERE 
			ID = OBJECT_ID ( N'[DBO].[BJ_WAITSTATS]') AND 
			OBJECTPROPERTY (ID, N'ISUSERTABLE') = 1
		) 
BEGIN 
	RAISERROR('ERROR [DBO].[BJ_WAITSTATS] TABLE DOES NOT EXIST', 16, 1) WITH NOWAIT 
	RETURN 
END 
*/

IF LOWER(@REPORT_FORMAT) NOT IN ('ALL','DETAIL','SIMPLE')
BEGIN 
	RAISERROR ('@REPORT_FORMAT MUST BE EITHER ''ALL'', ''DETAIL'', OR ''SIMPLE''',16,1) WITH NOWAIT 
	RETURN 
END 

IF LOWER(@REPORT_ORDER) NOT IN ('RESOURCE','SIGNAL','TOTAL') 
BEGIN 
	RAISERROR ('@REPORT_ORDER MUST BE EITHER ''RESOURCE'', ''SIGNAL'', OR ''TOTAL''',16,1) WITH NOWAIT 
	RETURN 
END 

IF LOWER(@REPORT_FORMAT) = 'SIMPLE' AND LOWER(@REPORT_ORDER) <> 'TOTAL' 
BEGIN 
	RAISERROR ('@REPORT_FORMAT IS SIMPLE SO ORDER DEFAULTS TO ''TOTAL''', 16,1) WITH NOWAIT 
	SELECT @REPORT_ORDER = 'TOTAL' 
END 

SELECT 
	@NOW=MAX(NOW), 
	@BEGINTIME=MIN(NOW), 
	@ENDTIME=MAX(NOW) 
FROM 
	[DBA].[DBO].[BJ_WAITSTATS] 
WHERE 
	[WAIT_TYPE] = 'TOTAL' 

--- SUBTRACT WAITFOR, SLEEP, AND RESOURCE_QUEUE FROM TOTAL 
SELECT
	@TOTALWAITCOUNTS = SUM([WAITING_TASKS_COUNT]), 
	@TOTALWAIT = SUM([WAIT_TIME_MS]) + 1, 
	@TOTALSIGNALWAIT = SUM([SIGNAL_WAIT_TIME_MS]) + 1 
FROM 
	DBA.DBO.BJ_WAITSTATS 
WHERE 
	[WAIT_TYPE] NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'TOTAL' ,'WAITFOR', '***TOTAL***') AND 
	[NOW] = @NOW 

SELECT 
	@TOTALRESOURCEWAIT = 1 + @TOTALWAIT - @TOTALSIGNALWAIT 

-- INSERT ADJUSTED TOTALS, RANK BY PERCENTAGE DESCENDING 
DELETE 
	DBA.DBO.BJ_WAITSTATS 
WHERE 
	[WAIT_TYPE] = '***TOTAL***' AND 
	NOW = @NOW 

INSERT INTO DBA.DBO.BJ_WAITSTATS 
SELECT 
	'***TOTAL***', 
	@TOTALWAITCOUNTS,
	@TOTALWAIT, 
	0, 
	@TOTALSIGNALWAIT, 
	@NOW

SELECT 
	'START TIME' = @BEGINTIME,
	'END TIME' = @ENDTIME, 
	'DURATION (HH:MM:SS:MS)' = CONVERT(VARCHAR(50),
	@ENDTIME - @BEGINTIME,14), 
	'REPORT FORMAT' = @REPORT_FORMAT, 
	'REPORT ORDER' = @REPORT_ORDER 

IF LOWER(@REPORT_FORMAT) IN ('ALL','DETAIL') 
BEGIN 
	----- FORMAT=DETAIL, COLUMN ORDER IS RESOURCE, SIGNAL, TOTAL. ORDER BY RESOURCE DESC 
	IF LOWER(@REPORT_ORDER) = 'RESOURCE' 
		SELECT 
			[WAIT_TYPE],
			[WAITING_TASKS_COUNT], 
			'RESOURCE WT (T1-T0)' = [WAIT_TIME_MS]-[SIGNAL_WAIT_TIME_MS], 
			'RES_WT_%' = CAST (100*([WAIT_TIME_MS] - [SIGNAL_WAIT_TIME_MS]) / @TOTALRESOURCEWAIT AS NUMERIC(20,1)), 
			'SIGNAL WT (T2-T1)' = [SIGNAL_WAIT_TIME_MS], 
			'SIG_WT_%' = CAST (100*[SIGNAL_WAIT_TIME_MS] / @TOTALSIGNALWAIT AS NUMERIC(20,1)), 
			'TOTAL WT (T2-T0)' = [WAIT_TIME_MS], 
			'WT_%' = CAST (100*[WAIT_TIME_MS] / @TOTALWAIT AS NUMERIC(20,1)) 
		FROM 
			DBA.DBO.BJ_WAITSTATS 
		WHERE 
			[WAIT_TYPE] NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'TOTAL', 'WAITFOR') AND 
			[NOW] = @NOW 
		ORDER BY 
			'RES_WT_%' DESC 

----- FORMAT = DETAIL, COLUMN ORDER SIGNAL, RESOURCE, TOTAL. ORDER BY SIGNAL DESC 
IF LOWER(@REPORT_ORDER) = 'SIGNAL' 
	SELECT 
		[WAIT_TYPE], 
		[WAITING_TASKS_COUNT], 
		'SIGNAL WT (T2-T1)' = [SIGNAL_WAIT_TIME_MS], 
		'SIG_WT_%' = CAST (100*[SIGNAL_WAIT_TIME_MS] / @TOTALSIGNALWAIT AS NUMERIC(20,1)), 
		'RESOURCE WT (T1-T0)' = [WAIT_TIME_MS]-[SIGNAL_WAIT_TIME_MS], 
		'RES_WT_%' = CAST (100*([WAIT_TIME_MS] - [SIGNAL_WAIT_TIME_MS]) /@TOTALRESOURCEWAIT AS NUMERIC(20,1)), 
		'TOTAL WT (T2-T0)' = [WAIT_TIME_MS], 
		'WT_%' = CAST (100*[WAIT_TIME_MS] / @TOTALWAIT AS NUMERIC(20,1)) 
	FROM 
		DBA.DBO.BJ_WAITSTATS 
	WHERE 
		[WAIT_TYPE] NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'TOTAL', 'WAITFOR') AND
		[NOW] = @NOW 
	ORDER BY 
		'SIG_WT_%' DESC 

----- FORMAT=DETAIL, COLUMN ORDER TOTAL, RESOURCE, SIGNAL. ORDER BY TOTAL DESC 
IF LOWER(@REPORT_ORDER) = 'TOTAL' 
	SELECT 
		[WAIT_TYPE], 
		[WAITING_TASKS_COUNT], 
		'TOTAL WT (T2-T0)' = [WAIT_TIME_MS], 
		'WT_%' = CAST (100*[WAIT_TIME_MS] / @TOTALWAIT AS NUMERIC(20,1)), 
		'RESOURCE WT (T1-T0)' = [WAIT_TIME_MS]-[SIGNAL_WAIT_TIME_MS], 
		'RES_WT_%' = CAST (100*([WAIT_TIME_MS] - [SIGNAL_WAIT_TIME_MS]) / @TOTALRESOURCEWAIT AS NUMERIC(20,1)), 
		'SIGNAL WT (T2-T1)' = [SIGNAL_WAIT_TIME_MS], 
		'SIG_WT_%' = CAST (100*[SIGNAL_WAIT_TIME_MS] / @TOTALSIGNALWAIT AS NUMERIC(20,1)) 
	FROM 
		DBA.DBO.BJ_WAITSTATS 
	WHERE 
		[WAIT_TYPE] NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'TOTAL', 'WAITFOR') AND 
		[NOW] = @NOW 
	ORDER BY 
		'WT_%' DESC 
END 
ELSE 
	---- SIMPLE FORMAT, TOTAL WAITS ONLY 
	SELECT 
		[WAIT_TYPE], [WAIT_TIME_MS], PERCENTAGE = CAST (100*[WAIT_TIME_MS] / @TOTALWAIT AS NUMERIC(20,1)) 
	FROM 
		DBA.DBO.BJ_WAITSTATS 
	WHERE 
		[WAIT_TYPE] NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'TOTAL', 'WAITFOR') AND 
		[NOW] = @NOW 
	ORDER BY 
		PERCENTAGE DESC 

---- COMPUTE CPU RESOURCE WAITS 
SELECT 
	'TOTAL WAITS' = [WAIT_TIME_MS], 
	'TOTAL SIGNAL=CPU WAITS' = [SIGNAL_WAIT_TIME_MS], 
	'CPU RESOURCE WAITS % = SIGNAL WAITS / TOTAL WAITS' = CAST (100*[SIGNAL_WAIT_TIME_MS] / [WAIT_TIME_MS] AS NUMERIC(20,1)), 
	[NOW] 
FROM 
	[DBA].[DBO].[BJ_WAITSTATS]
WHERE 
	[WAIT_TYPE] = '***TOTAL***' 
ORDER BY 
	[NOW] 

SET NOCOUNT OFF

go

USE master
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'sp_helptable' 
	   AND 	  type = 'P')
    DROP PROCEDURE  sp_helptable
GO

/**  
* Create        : choi bo ra(ceusee)  
* SP Name       : dbo.sp_helptable  
* Purpose       : sp_hlep 중에 필요한 부분만 사용  
* E-mail        : ceusee@gmail.com  
* Create date   : 2007-05-09  
* Return Code   :  
    0 : Success.   
    4000 : Fail.  
    4003 : Record Not Find.  
* Modification Memo :  
-- 테이블 정보  
Name    Owner    Type  Filegroup   rows  reserved  data  index unused Create Date  
  
-- 인덱스 정보  
index_name  index_Keys PK clusted(Y/N) Unique(Y/N) fillfactor Filegroup  
  
-- indetity  
identity seed  increment  
  
-- 컬럼 정보  
column_name  type  Cmputed  Length Prec Scale Nullable  
  
-- 제약조건  
sp_helpconstraint warehouse01   나오는 결과  
**/  
CREATE PROCEDURE dbo.sp_helptable  
    @objectName     NVARCHAR(776) = NULL  
AS  
/* COMMON DECLARE */  
SET NOCOUNT ON  
DECLARE @errCode        INT  
  
/* USER DECLARE */  

-- TABLE DECLARE 
create table #spt_space_temp 
( 
 objid       int default 0, 
 name        nvarchar(128) null,  
 rows        int null,  
 reserved    nvarchar(18) null,  
 data        nvarchar(18) null,  
 indexp        nvarchar(18) null,  
 unused        nvarchar(18) null  
)  


create table #spt_filegroup_temp  
(  
    file_group nvarchar(128) null  
)  

declare @no varchar(35), @yes varchar(35), @none varchar(35)  
declare @dbname sysname, @objid int, @type char(2)  
  
-- INDEX DECLARE  
declare @indid smallint, @groupid smallint, @indname sysname, @groupname sysname,   
        @status int, @keys nvarchar(2126), @fill_factor tinyint,  @thiskey nvarchar(131)  
declare @empty varchar(1) select @empty = ''  
declare @des1   varchar(35), -- 35 matches spt_values  
  @des2   varchar(35),  
  @des4   varchar(35),  
  @des16          varchar(35),  
  @des32   varchar(35),  
  @des64   varchar(35),  
  @des2048  varchar(35),  
  @des4096  varchar(35),  
  @des8388608  varchar(35),  
  @des16777216 varchar(35)  
    
-- INDENTITY DECLARE  
declare @colname sysname  
  
-- COLUMN DECLARE  
declare @numtypes nvarchar(80)  
select @numtypes = N'tinyint,smallint,decimal,int,real,money,float,numeric,smallmoney'  
  
-- CONSTRAINT DECLARE  
declare  @cnstdes  nvarchar(4000), -- string to build up index desc  
   @cnstname  sysname,       -- name of const. currently under consideration  
   @i    int,  
   @cnstid  int,  
   @cnsttype  character(2)  
  
IF @objectName IS NULL   
begin  
    EXEC sp_help NULL  
    RETURN  
end  
-- OBTAIN DISPLAY STRINGS FROM spt_values UP FRONT --  
select @no = name from master.dbo.spt_values where type = 'B' and number = 0  
select @yes = name from master.dbo.spt_values where type = 'B' and number = 1  
select @none = name from master.dbo.spt_values where type = 'B' and number = 2  
  
-- Make sure the @objname is local to the current database.  
select @dbname = parsename(@objectname,3)  
  
if @dbname is not null and @dbname <> db_name()  
begin  
 raiserror(15250,-1,-1)  
 return (-1)  
end  
-- obejct check   
select @objid = id, @type = xtype  from sysobjects  where id = object_id(@objectname)    
if @objid = null   
begin  
      raiserror(15009,-1,-1,@objectname,@dbname)  
      return (-1)  
end  
  
  
if  @type in ('U', 'S')  
begin  
  
    /**************************************************************************************  
        TABLE Information  
        Name    Owner    Type  Filegroup   rows  reserved  data  index unused Create Date  
    ****************************************************************************************/  
    DECLARE @strSql nvarchar(50)
    SET @strSql = N'exec sp_spaceused ' + @objectname

    insert #spt_space_temp(name,rows,reserved,data,indexp,unused)
    exec sp_executesql @strSql
    
    -- tempdb와 생성된 DB와의 collate 가 틀릴 경우를 대비해서
    --update #spt_space_temp set objid = @objid
  
    SET @strSql = N'exec sp_objectfilegroup ' + convert(nvarchar, @objid) 
    insert #spt_filegroup_temp
    exec sp_executesql @strSql

    select o.name, user_name(o.uid) as owner, substring(v.name, 5,31) as type,  
            (select file_group from #spt_filegroup_temp) as filegroup,   
            t.rows, t.reserved, t.data, t.indexp, t.unused, o.crdate as create_date  
    from sysobjects as o join master.dbo.spt_values as v on o.xtype = substring(v.name,1,2) collate SQL_Latin1_General_CP1_CI_AS  
           join #spt_space_temp t on o.name = t.name collate SQL_Latin1_General_CP1_CI_AS
    where o.id = @objid and v.type = 'O9T' 

  
   /***************************************************************************  
    INDEX Information  
    index_name  index_Keys PK clusted(Y/N) Unique(Y/N) fillfactor Filegroup   
   ****************************************************************************/ 
  DECLARE @count  INT
  SET @count = 0
  select  @count = count(indid) from sysindexes  
   where id = @objid and indid > 0 and indid < 255 and (status & 64)=0 
  
  IF @count = 0 
  BEGIN
	SELECT 'No Index Information' AS [Index_name]
  END
  ELSE
  BEGIN
    
        -- OPEN CURSOR OVER INDEXES  
     declare ms_crs_ind cursor local static for  
      select indid, groupid, name, status, OrigFillFactor from sysindexes  
       where id = @objid and indid > 0 and indid < 255 and (status & 64)=0 order by indid  
       
     open ms_crs_ind  
     fetch ms_crs_ind into @indid, @groupid, @indname, @status, @fill_factor  
      
         -- IF NO INDEX, QUIT  
         if @@fetch_status < 0  
         begin  
          deallocate ms_crs_ind  
          raiserror(15472,-1,-1) --'Object does not have any indexes.'  
         end  
           
         -- create temp table  
         create table #spindtab  
         (  
          index_name   sysname collate database_default NOT NULL,  
          stats    int,  
          groupname   sysname collate database_default NOT NULL,  
          index_keys   nvarchar(2126) collate database_default NOT NULL,   
          fill_factor         tinyint  
         )   
  
              
            -- Now check out each index, figure out its type and keys and  
         -- save the info in a temporary table that we'll print out at the end.  
         while @@fetch_status >= 0  
         begin  
           
          select @keys = index_col(@objectname, @indid, 1), @i = 2  
          
          if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)  
              select @keys = @keys  + '(-)'  
          
            select @thiskey = index_col(@objectname, @indid, @i)  
            
          if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
           select @thiskey = @thiskey + '(-)'  
          
                while (@thiskey is not null )  
          begin  
           select @keys = @keys + ', ' + @thiskey, @i = @i + 1  
           select @thiskey = index_col(@objectname, @indid, @i)  
           if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
            select @thiskey = @thiskey + '(-)'  
             end  
                declare @sql nvarchar(100)  
                set @sql = N'select @groupname_t= groupname from sysfilegroups where groupid = '+ convert(nvarchar,@groupid)  
                  
                execute sp_executesql @sql, N'@groupname_t sysname output', @groupname_t = @groupname output  
                -- INSERT ROW FOR INDEX  
          insert into #spindtab values (@indname, @status, @groupname, @keys, @fill_factor)  
      
          -- Next index  
          fetch ms_crs_ind into @indid, @groupid, @indname, @status, @fill_factor  
         end  
         deallocate ms_crs_ind  
  
         -- Type Value  
         select @des1 = name from master.dbo.spt_values where type = 'I' and number = 1  
            select @des2 = name from master.dbo.spt_values where type = 'I' and number = 2  
            select @des4 = name from master.dbo.spt_values where type = 'I' and number = 4  
            select @des16 = name from master.dbo.spt_values where type = 'I' and number = 16  
            select @des32 = name from master.dbo.spt_values where type = 'I' and number = 32  
            select @des64 = name from master.dbo.spt_values where type = 'I' and number = 64  
            select @des2048 = name from master.dbo.spt_values where type = 'I' and number = 2048  
            select @des4096 = name from master.dbo.spt_values where type = 'I' and number = 4096  
            select @des8388608 = name from master.dbo.spt_values where type = 'I' and number = 8388608  
            select @des16777216 = name from master.dbo.spt_values where type = 'I' and number = 16777216  
           
         select index_name, index_keys,  
                    case when (stats & 2048) <> 0 then @des2048 else @empty end as 'PK',  
                    case when (stats & 16) <> 0 then @des16 else @empty end as 'Clustered',  
                    case when (stats & 2) <> 0 then @des2 else 'no' end as 'Unique',  
                    fill_factor,groupname,  
                    case when (stats & 1)<>0 then ', '+@des1 else @empty end  
                    + case when (stats & 4)<>0 then ', '+@des4 else @empty end  
                    + case when (stats & 64)<>0 then ', '+@des64 else case when (stats & 32)<>0 then ', '+@des32 else @empty end end  
                    + case when (stats & 4096)<>0 then ', '+@des4096 else @empty end  
                    + case when (stats & 8388608)<>0 then ', '+@des8388608 else @empty end  
              + case when (stats & 16777216)<>0 then ', '+@des16777216 else @empty end as 'Etc'  
           from #spindtab  
    END
    /****************************************************  
     indetity  
     identity seed  increment  
    *****************************************************/  
    select @colname  = name from syscolumns where id = @objid and colstat & 1 = 1  
    select  
    'Identity'    = isnull(@colname,'No identity column defined.'),  
    'Seed'     = ident_seed(@objectName),  
    'Increment'    = ident_incr(@objectName),  
    'Curr Identity'         = ident_current(@objectName),  
    'Not For Replication' = ColumnProperty(@objid, @colname, 'IsIDNotForRepl')  
      
    /************************************************************  
      COLUMN Information  
      column_name  type  Cmputed  Length Prec Scale Nullable  
    *************************************************************/  
      
    select  
   'Column_name'   = name,  
   'Type'     = type_name(xusertype),  
   'Computed'    = case when iscomputed = 0 then @no else @yes end,  
   'Length'    = convert(int, length),  
   'Prec'     = case when charindex(type_name(xtype), @numtypes) > 0  
          then convert(char(5),ColumnProperty(id, name, 'precision'))  
          else '     ' end,  
   'Scale'     = case when charindex(type_name(xtype), @numtypes) > 0  
          then convert(char(5),OdbcScale(xtype,xscale))  
          else '     ' end,  
   'Nullable'    = case when isnullable = 0 then @no else @yes end  
    from syscolumns where id = @objid and number = 0 order by colid  
      
    /**************************************************************  
      -- 제약조건  
      sp_helpconstraint warehouse01   나오는 결과  
    ***************************************************************/  
      
    create table #spcnsttab  
 (  
  cnst_id   int   NOT NULL  
  ,cnst_type   nvarchar(146) collate database_default NULL   -- 128 for name + text for DEFAULT  
  ,cnst_name   sysname  collate database_default NOT NULL  
  ,cnst_nonblank_name sysname  collate database_default NOT NULL  
  ,cnst_2type   character(2) collate database_default NULL  
  ,cnst_disabled  bit    NULL  
  ,cnst_notrepl  bit    NULL  
  ,cnst_delcasc  bit    NULL  
  ,cnst_updcasc  bit    NULL  
  ,cnst_keys   nvarchar(2126) collate database_default NULL -- see @keys above for length descr  
 )  
 declare ms_crs_cnst cursor local static for  
  select id, xtype, name from sysobjects where parent_obj = @objid  
   and xtype in ('C ','F ', 'D ')   
  for read only  
    -- Now check out each constraint, figure out its type and keys and  
 -- save the info in a temporary table that we'll print out at the end.  
 open ms_crs_cnst  
    fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname  
 while @@fetch_status >= 0  
 begin  
        if @cnsttype = 'F '  
  begin  
   -- OBTAIN TWO TABLE IDs  
   declare @fkeyid int, @rkeyid int  
   select @fkeyid = fkeyid, @rkeyid = rkeyid from sysreferences where constid = @cnstid  
  
   -- USE CURSOR OVER FOREIGN KEY COLUMNS TO BUILD COLUMN LISTS  
   -- (NOTE: @keys HAS THE FKEY AND @cnstdes HAS THE RKEY COLUMN LIST)  
   declare ms_crs_fkey cursor local for select fkey, rkey from sysforeignkeys where constid = @cnstid  
   open ms_crs_fkey  
   declare @fkeycol smallint, @rkeycol smallint  
   fetch ms_crs_fkey into @fkeycol, @rkeycol  
   select @keys = col_name(@fkeyid, @fkeycol), @cnstdes = col_name(@rkeyid, @rkeycol)  
   fetch ms_crs_fkey into @fkeycol, @rkeycol  
   while @@fetch_status >= 0  
   begin  
    select @keys = @keys + ', ' + col_name(@fkeyid, @fkeycol),  
      @cnstdes = @cnstdes + ', ' + col_name(@rkeyid, @rkeycol)  
    fetch ms_crs_fkey into @fkeycol, @rkeycol  
   end  
   deallocate ms_crs_fkey  
  
   -- ADD ROWS FOR BOTH SIDES OF FOREIGN KEY  
   insert into #spcnsttab  
    (cnst_id, cnst_type,cnst_name,cnst_nonblank_name,  
     cnst_keys, cnst_disabled,  
     cnst_notrepl, cnst_delcasc, cnst_updcasc, cnst_2type)  
   values  
    (@cnstid, 'FOREIGN KEY', @cnstname, @cnstname,  
     @keys, ObjectProperty(@cnstid, 'CnstIsDisabled'),  
     ObjectProperty(@cnstid, 'CnstIsNotRepl'),  
     ObjectProperty(@cnstid, 'CnstIsDeleteCascade'),  
     ObjectProperty(@cnstid, 'CnstIsUpdateCascade'),  
     @cnsttype)  
   insert into #spcnsttab  
    (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,  
     cnst_keys,  
     cnst_2type)  
   select  
    @cnstid,' ', ' ', @cnstname,  
     'REFERENCES ' + db_name()  
      + '.' + rtrim(user_name(ObjectProperty(@rkeyid,'ownerid')))  
      + '.' + object_name(@rkeyid) + ' ('+@cnstdes + ')',  
     @cnsttype  
  end  
        else if @cnsttype = 'C '  
  begin  
   select @i = 1  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   while @cnstdes is not null  
   begin  
    if @i=1  
     -- Check constraint  
     insert into #spcnsttab  
      (cnst_id, cnst_type ,cnst_name ,cnst_nonblank_name,  
       cnst_keys, cnst_disabled, cnst_notrepl, cnst_2type)  
     select @cnstid,  
      case when info = 0 then 'CHECK Table Level '  
       else 'CHECK on column ' + col_name(@objid ,info) end,  
      @cnstname ,@cnstname ,substring(@cnstdes,1,2000),  
      ObjectProperty(@cnstid, 'CnstIsDisabled'),  
      ObjectProperty(@cnstid, 'CnstIsNotRepl'),  
      @cnsttype  
     from sysobjects where id = @cnstid  
    else  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
  
    if len(@cnstdes) > 2000  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype  
  
    select @cnstdes = null  
    select @i = @i + 1  
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   end  
  end  
        else if @cnsttype = 'D '  
  begin  
   select @i = 1  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   while @cnstdes is not null  
   begin  
    if @i=1  
     insert into #spcnsttab  
      (cnst_id,cnst_type ,cnst_name ,cnst_nonblank_name ,cnst_keys, cnst_2type)  
     select @cnstid, 'DEFAULT on column ' + col_name(@objid ,info),  
      @cnstname ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
     from sysobjects where id = @cnstid  
    else  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
  
    if len(@cnstdes) > 2000  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype  
  
    select @i = @i + 1  
    select @cnstdes = null  
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   end  
  end  
     
  fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname  
 end  --of major loop  
 deallocate ms_crs_cnst  
      
    insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.domain,'RULE on column ' + c.name + ' (bound with sp_bindrule)',  
  object_name(c.domain), object_name(c.domain), text, 'R '  
 from syscolumns c, syscomments m  
 where c.id = @objid and m.id = c.domain and ObjectProperty(c.domain, 'IsRule') = 1  
  
   
    insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.cdefault, 'DEFAULT on column ' + c.name + ' (bound with sp_bindefault)',  
  object_name(c.cdefault),object_name(c.cdefault), text, 'D '  
 from syscolumns c,syscomments m  
 where c.id = @objid and m.id = c.cdefault and ObjectProperty(c.cdefault, 'IsConstraint') = 0  
  
    -- Now print out the contents of the temporary index table.  
 if exists (select * from #spcnsttab)  
  select  
   'constraint_type' = cnst_type,  
   'constraint_name' = cnst_name,  
   'delete_action'=  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ') Then  
       CASE When cnst_delcasc = 1  
        Then 'Cascade' else 'No Action' end  
      Else '(n/a)'  
     END,  
   'update_action'=  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ') Then  
       CASE When cnst_updcasc = 1  
        Then 'Cascade' else 'No Action' end  
      Else '(n/a)'  
     END,  
   'status_enabled' =  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ','C ') Then  
       CASE When cnst_disabled = 1  
        then 'Disabled' else 'Enabled' end  
      Else '(n/a)'  
     END,  
   'status_for_replication' =  
     CASE  
      When cnst_name = ' ' Then ' '  
      When cnst_2type in ('F ','C ') Then  
       CASE When cnst_notrepl = 1  
        Then 'Not_For_Replication' else 'Is_For_Replication' end  
      Else '(n/a)'  
     END,  
   'constraint_keys' = cnst_keys  
  from #spcnsttab order by cnst_nonblank_name ,cnst_name desc  
 else  
  raiserror(15469,-1,-1) --'No constraints have been defined for this object.'  
   
 if exists (select * from sysreferences where rkeyid = @objid)  
  select  
   'Table is referenced by foreign key' =  
    db_name() + '.'  
     + rtrim(user_name(ObjectProperty(fkeyid,'ownerid')))  
     + '.' + object_name(fkeyid)  
     + ': ' + object_name(constid)  
   from sysreferences where rkeyid = @objid order by 1  
-- else  
--  raiserror(15470,-1,-1) --'No foreign keys reference this table.'  

drop table #spt_filegroup_temp
drop table #spt_space_temp
      
end  
else -- ETC Type  
    EXEC sp_help @objectname  
         
RETURN  
  
ERRORHANDLER:  
BEGIN  
    RETURN   
END   
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant all on sp_helptable to public
go

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
	set @vsql = 'bcp "select cmd from ##tmp where dbname = ''' +db_name()+''' and rownumber between '+cast((@page-1) * @pagesize as varchar(200)) + ' and ' + cast(@pagesize * @page as varchar(200)) +'" queryout ' + @vpath + @vFileName + cast(@page as varchar
(10))+'.sql -Sgmkt2005 -T -c' 
	
	EXEC master.dbo.xp_cmdshell @vsql,no_output
	
	set @vsql = 'start osql -i ' + @vpath + @vFileName + cast(@page as varchar(10))+'.sql -S gmkt2005 -E -o ' + @vpath + 'Log@' + @vFileName + cast(@page as varchar(10))+ '.log'
	--print @vsql

	insert into ##osql values(db_name(),@vsql)
	set @page = @page + 1
end

delete from ##tmp where dbname = db_name()

set @vsql = 'bcp "select cmd from ##osql where dbname = ''' + db_name() + '''" queryout ' + @vpath + db_name() + @vFileName + '.cmd -Sgmkt2005 -T -c' 
EXEC master.dbo.xp_cmdshell @vsql,no_output
delete from ##osql where dbname = db_name()

set @vsql = @vpath + db_name() + @vFileName +'.cmd'
EXEC master.dbo.xp_cmdshell @vsql,no_output
RETURN


go

/*************************************************************************  
* 프로시저명  : dbo.sp_leadblocker2 
* 작성정보    : 2007-08-11 김태환
* 관련페이지  :  
* 내용        :
* 수정정보    : DMV를 이용한 blocked session id 확인
**************************************************************************/
CREATE procedure dbo.sp_leadblocker2 (@latch int = 0, @fast int = 1)  
AS 
	SET NOCOUNT ON

	SELECT 
		'KILL ' + CAST(req.SESSION_ID AS VARCHAR(5)) AS killStr
	,	'DBCC INPUTBUFFER(' + CAST(req.SESSION_ID AS VARCHAR(5)) + ')' AS inputBufferStr
	,	req.open_transaction_count
	,	(select text from sys.dm_exec_sql_text(sql_handle)) as sql
	,	req.last_wait_type
	, 	req.wait_type
	,	req.status
	, 	se.login_name
	,	se.host_name
	,	req.blocking_session_id
	,	DB_NAME(req.database_id) as user_db_name
	FROM sys.dm_exec_requests as req WITH (NOLOCK)
	INNER JOIN sys.dm_exec_sessions as se WITH (NOLOCK) ON req.session_id = se.session_id
	WHERE req.blocking_session_id IN (SELECT blocking_session_id FROM sys.dm_exec_requests WITH (NOLOCK) WHERE blocking_session_id > 0 AND blocking_session_id <> session_id) AND req.blocking_session_id = 0

	SET NOCOUNT OFF

go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/**************************************************************************************************************  
SP    명 : master.dbo.sp_opentranBlocker
작성정보: 2005-04-18 양은선
관련페이지 :
내용	    : open_tran = 1인데 select인 쿼리가 blocking을 유발하는지 모니터링
===============================================================================
				수정정보 
===============================================================================

**************************************************************************************************************/ 
create procedure dbo.sp_opentranBlocker
AS 

SET NOCOUNT ON

SELECT open_tran, 'KILL ' + CONVERT(VARCHAR(5), spid) AS killStr, 'DBCC INPUTBUFFER(' + CONVERT(VARCHAR(5), spid) + ')' AS bufStr
, spid, blocked, waittype, lastwaittype, hostname, cmd
FROM master..sysprocesses
WHERE open_tran = 1 AND status = 'sleeping' AND cmd = 'awaiting command' AND hostname LIKE 'GOODSDAQ%' AND loginame = 'goodsdaq'



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
go
CREATE PROC dbo.sp_pssdiag_cleanup @AppName sysname='PSSDIAG'
AS
  EXEC dbo.sp_trace 'OFF', @AppName=@AppName

EXEC('DBCC CACHEPROFILE(2)') -- Turn off cache profiling (wrap in EXEC() to prevent error on 7.0)

DECLARE @spid int, @cmd varchar(30)
DECLARE osqls CURSOR FOR
SELECT spid FROM master..sysprocesses
WHERE hostname=@AppName AND spid<>@@SPID
FOR READ ONLY

OPEN osqls
FETCH osqls INTO @spid
WHILE @@FETCH_STATUS=0 BEGIN
  SET @cmd='KILL '+CAST(@spid AS varchar)
  EXEC(@cmd)
  FETCH osqls INTO @spid
END
CLOSE osqls
DEALLOCATE osqls

--Assuming that these procs actually ship with the product, there's no 
--reason to drop them
/*
	--Drop our procs
	IF OBJECT_ID('dbo.sp_code_runner','P') IS NOT NULL
		DROP PROC dbo.sp_code_runner

	IF OBJECT_ID('dbo.sp_trace','P') IS NOT NULL
		DROP PROC dbo.sp_trace

	IF OBJECT_ID('dbo.sp_blocker_pss70','P') IS NOT NULL
		DROP PROC dbo.sp_blocker_pss70

	IF OBJECT_ID('dbo.sp_blocker_pss80','P') IS NOT NULL
		DROP PROC dbo.sp_blocker_pss80

	IF OBJECT_ID('dbo.sp_sqldiag','P') IS NOT NULL
		DROP PROC dbo.sp_sqldiag

	IF OBJECT_ID('dbo.sp_tmpregread','P') IS NOT NULL
		DROP PROC dbo.sp_tmpregread

	IF OBJECT_ID('dbo.sp_tmpregenumvalues','P') IS NOT NULL
		DROP PROC dbo.sp_tmpregenumvalues
*/

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
create procedure dbo.sp_spaceused2 --- 1996/08/20 17:01
@objname nvarchar(776) = null,		-- The object we want size on.
@updateusage varchar(5) = false		-- Param. for specifying that
					-- usage info. should be updated.
as

declare @id	int			-- The object id of @objname.
declare @type	character(2) -- The object type.
declare	@pages	int			-- Working variable for size calc.
declare @dbname sysname
declare @dbsize dec(15,0)
declare @logsize dec(15)
declare @bytesperpage	dec(15,0)
declare @pagesperMB		dec(15,0)

/*Create temp tables before any DML to ensure dynamic
**  We need to create a temp table to do the calculation.
**  reserved: sum(reserved) where indid in (0, 1, 255)
**  data: sum(dpages) where indid < 2 + sum(used) where indid = 255 (text)
**  indexp: sum(used) where indid in (0, 1, 255) - data
**  unused: sum(reserved) - sum(used) where indid in (0, 1, 255)
*/
create table #spt_space
(
	rows		int null,
	reserved	dec(15) null,
	data		dec(15) null,
	indexp		dec(15) null,
	unused		dec(15) null
)

/*
**  Check to see if user wants usages updated.
*/

if @updateusage is not null
	begin
		select @updateusage=lower(@updateusage)

		if @updateusage not in ('true','false')
			begin
				raiserror(15143,-1,-1,@updateusage)
				return(1)
			end
	end
/*
**  Check to see that the objname is local.
*/
if @objname IS NOT NULL
begin

	select @dbname = parsename(@objname, 3)

	if @dbname is not null and @dbname <> db_name()
		begin
			raiserror(15250,-1,-1)
			return (1)
		end

	if @dbname is null
		select @dbname = db_name()

	/*
	**  Try to find the object.
	*/
	select @id = null
	select @id = id, @type = xtype
		from sysobjects
			where id = object_id(@objname)

	/*
	**  Does the object exist?
	*/
	if @id is null
		begin
			raiserror(15009,-1,-1,@objname,@dbname)
			return (1)
		end


	if not exists (select * from sysindexes
				where @id = id and indid < 2)

		if      @type in ('P ','D ','R ','TR','C ','RF') --data stored in sysprocedures
				begin
					raiserror(15234,-1,-1)
					return (1)
				end
		else if @type = 'V ' -- View => no physical data storage.
				begin
					raiserror(15235,-1,-1)
					return (1)
				end
		else if @type in ('PK','UQ') -- no physical data storage. --?!?! too many similar messages
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


IF OBJECT_ID('sp_start_trace') IS NOT NULL
  DROP PROC sp_start_trace
GO
CREATE PROC sp_start_trace @FileName sysname=NULL,
@TraceName sysname='tsqltrace',
@Options int=2,
@MaxFileSize bigint=5,
@StopTime datetime=NULL,
@Events varchar(300) = NULL,
--  11 - RPC:Starting
--  13 - SQL:BatchStarting
--  14 - Connect
--  15 - Disconnect
--  16 - Attention
--  17 - Existing Connection
--  33 - Exception
--  42 - SP:Starting
--  43 - SP:Completed
--  45 - SP:StmtCompleted
--  55 - Hash Warning
--  67 - Execution Warnings
--  69 - Sort Warnings
--  79 - Missing Column Statistics
--  80 - Missing Join Predicate
@Cols varchar(300) = NULL,
@IncludeDBIdFilter int = NULL,  -- DBId
@IncludeTextFilter sysname=NULL, @ExcludeTextFilter sysname=NULL,
@IncludeObjIdFilter int=NULL, @ExcludeObjIdFilter int=NULL, 
@TraceId int = NULL
/*
Object: sp_start_trace
Description: Starts a Profiler-like trace using Transact-SQL eXtended Procedure calls.

Usage: sp_start_trace @FileName           sysname      default: c:\temp\YYYYMMDDhhmissmmm.trc -- Specifies the trace file name (SQL Server always appends .trc extension)
@TraceName          sysname      default: tsqltrace -- Specifies the name of the trace
@Options            int          default: 2 (TRACE_FILE_ROLLOVER)
@MaxFileSize        bigint       default: 5 (MB)
@StopTime           datetime     default: NULL
@Events             varchar(300) default: SP-related events and errors/warnings -- Comma-delimited list specifying the events numbers to trace
@Cols               varchar(300) default: All columns -- Comma-delimited list specifying the column numbers to trace
@IncludeTextFilter  sysname      default: NULL -- String mask specifying what TextData strings to include in the trace
@ExcludeTextFilter  sysname      default: NULL -- String mask specifying what TextData strings to filter out of the trace
@IncludeObjIdFilter sysname      default: NULL -- Specifies the id of an object to target with the trace
@ExcludeObjIdFilter sysname      default: NULL -- Specifies the id of an object to exclude from the trace
@TraceId            int          default: NULL -- Specified the id of the trace to list when you specify the LIST option to @OnOff

Returns: (None)

$Author: Ken Henderson $. Email: khen@khen.com
@Updater Author : choi bora Email:ceusee@gmail.com Date :2007-06-05

$Revision: 2.0 $

Example: EXEC sp_start_trace -- Starts a trace
EXEC sp_start_trace @Filename='d:\mssql7\log\mytrace' -- Starts a trace with the specified file name
EXEC sp_start_trace @Events='37,43' -- Starts a trace the traps the specified event classes
EXEC sp_start_trace @Cols='1,2,3' -- Starts a trace that includes the specified columns
EXEC sp_start_trace @IncludeTextFilter='EXEC% FooProc%' -- Starts a trace that includes events matching the specified TextData mask
EXEC sp_start_trace @tracename='General Performance' -- Starts a trace using the specified name
EXEC sp_start_trace @filename = 'd:\mssql7\log\mytrace', -- Starts a trace with the specified parameters
		    @TraceName = 'General Performance',
		    @Options = 2, 
		    @MaxFileSize = 500,
		    @StopTime = NULL, 
		    @Events = '10,11,14,15,16,17,27,37,40,41,55,58,67,69,79,80,98',
		    @Cols = DEFAULT,
		    @IncludeTextFilter = NULL,
		    @IncludeObjIdFilter = NULL,
		    @ExcludeObjIdFilter = NULL

Created: 1999-04-01.  $Modtime: 2000-12-16 $.
*/
AS
SET NOCOUNT ON

--IF @FileName='/?' GOTO Help

-- Declare variables
DECLARE @OldQueueHandle int -- Queue handle of currently running trace queue
DECLARE @QueueHandle int -- Queue handle for new running trace queue
DECLARE @On bit  -- Necessary because of a bug in some of the sp_trace_xx procs
DECLARE @OurObjId int -- Used to keep us out of the trace log
DECLARE @OldTraceFile sysname -- File name of running trace
DECLARE @res int -- Result var for sp calls
SET @On=1

IF @Events IS NULL 
	SET @Events = '10,12,41,45'
ELSE IF @Events = 'A' 
	SET @Events = '11,13,14,15,16,17,33,42,43,45,55,67,69,79,80'

IF @Cols IS NULL
	SET @Cols='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44'  
ELSE IF @Cols = 'A'  -- All columns
	SET @Cols = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44'

-- Do some basic param validation
IF (@Cols IS NULL) BEGIN
  RAISERROR('You must specify the columns to trace.',16,10)
  RETURN -1
END

IF (@Events IS NULL) BEGIN
  RAISERROR('You must specify a list of trace events in @Events.',16,10)
  RETURN -1
END

-- Append the datetime to the file name to create a new, unique file name.
IF @FileName IS NULL SELECT @FileName = 'c:\TEMP\tsqltrace_' + CONVERT(CHAR(8),getdate(),112) + REPLACE(CONVERT(varchar(15),getdate(),114),':','')

-- Create the trace queue

EXEC @res=sp_trace_create @traceid=@QueueHandle OUT, @options=@Options, @tracefile=@FileName, @maxfilesize=@MaxFileSize, @stoptime=@StopTime
IF @res<>0 BEGIN
  IF @res=1 PRINT 'Trace not started.  Reason: Unknown error.'
  ELSE IF @res=10 PRINT 'Trace not started.  Reason: Invalid options. Returned when options specified are incompatible.'
  ELSE IF @res=12 PRINT 'Trace not started.  Reason: Error creating file. Returned if the file already exists, drive is out of space, or path does not exist.'
  ELSE IF @res=13 PRINT 'Trace not started.  Reason: Out of memory. Returned when there is not enough memory to perform the specified action.'
  ELSE IF @res=14 PRINT 'Trace not started.  Reason: Invalid stop time. Returned when the stop time specified has already happened.'
  ELSE IF @res=15 PRINT 'Trace not started.  Reason: Invalid parameters. Returned when the user supplied incompatible parameters.'
  RETURN @res
END 
PRINT 'Trace started.'
PRINT 'Trace Id: ' + CONVERT(nvarchar, @QueueHandle)
PRINT 'The trace file name is : '+@FileName+'.'


-- Specify the event classes and columns to trace
IF @Events IS NOT NULL BEGIN -- Loop through the @Events and @Cols strings, parsing out each event & column number and adding them to the trace definition
  IF RIGHT(@Events,1)<>',' SET @Events=@Events+',' -- Append a comma to satisfy the loop
  IF RIGHT(@Cols,1)<>',' SET @Cols=@Cols+',' -- Append a comma to satisfy the loop
  DECLARE @i int, @j int, @Event int, @Col int, @ColStr varchar(300)
  SET @i=CHARINDEX(',',@Events)
  WHILE @i<>0 BEGIN
    SET @Event=CAST(LEFT(@Events,@i-1) AS int)
    SET @ColStr=@Cols
    SET @j=CHARINDEX(',',@ColStr)
    WHILE @j<>0 BEGIN
      SET @Col=CAST(LEFT(@ColStr,@j-1) AS int)
      EXEC sp_trace_setevent @traceid=@QueueHandle, @eventid=@Event, @columnid=@Col, @on=@On
      SET @ColStr=SUBSTRING(@ColStr,@j+1,300)
      SET @j=CHARINDEX(',',@ColStr)
    END
    SET @Events=SUBSTRING(@Events,@i+1,300)
    SET @i=CHARINDEX(',',@Events)
  END
END

-- Set filters (default values avoid tracing the trace activity itself)
-- You can specify other filters like application name etc. by supplying strings to the @IncludeTextFilter/@ExcludeTextFilter parameters, separated by semicolons
SET @ExcludeTextFilter='sp_%trace%'+ISNULL(';'+@ExcludeTextFilter,'')  -- By default, keep our own activity from showing up
SET @OurObjId=OBJECT_ID('master..sp_start_trace')

EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=1, @logical_operator=0, @comparison_operator=7, @value=@ExcludeTextFilter
EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=1, @logical_operator=0, @comparison_operator=7, @value=N'EXEC% sp_%trace%'


IF @IncludeDBIdFilter IS NOT NULL EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=3, @logical_operator=0, @comparison_operator=0, @value=@IncludeDBIdFilter
IF @IncludeTextFilter IS NOT NULL EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=1, @logical_operator=0, @comparison_operator=6, @value=@IncludeTextFilter
IF @IncludeObjIdFilter IS NOT NULL EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=22, @logical_operator=0, @comparison_operator=0, @value=@IncludeObjIdFilter
IF @ExcludeObjIdFilter IS NOT NULL EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=22, @logical_operator=0, @comparison_operator=1, @value=@ExcludeObjIdFilter

EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=22, @logical_operator=0, @comparison_operator=1, @value=@OurObjId

-- Turn the trace on
EXEC sp_trace_setstatus @traceid=@QueueHandle, @status=1

-- Record the trace queue handle for subsequent jobs.  (This allows us to know how to stop the trace.)
IF OBJECT_ID('tempdb..TraceQueue') IS NULL BEGIN
  CREATE TABLE tempdb..TraceQueue (TraceID int, TraceName varchar(20), TraceFile sysname)
  INSERT tempdb..TraceQueue VALUES(@QueueHandle, @TraceName, @FileName)
END ELSE BEGIN
  IF EXISTS(SELECT * FROM tempdb..TraceQueue WHERE TraceName = @TraceName) BEGIN
    UPDATE tempdb..TraceQueue SET TraceID = @QueueHandle, TraceFile=@FileName WHERE TraceName = @TraceName
  END ELSE BEGIN
    INSERT tempdb..TraceQueue VALUES(@QueueHandle, @TraceName, @FileName)
  END
END
RETURN 0

Help:
EXEC sp_usage @objectname='sp_start_trace',@desc='Starts a Profiler-like trace using Transact-SQL eXtended Procedure calls.',
			@parameters='@FileName           sysname      default: c:\temp\YYYYMMDDhhmissmmm.trc -- Specifies the trace file name (SQL Server always appends .trc extension)
@TraceName          sysname      default: tsqltrace -- Specifies the name of the trace
@Options            int          default: 2 (TRACE_FILE_ROLLOVER)
@MaxFileSize        bigint       default: 5 (MB)
@StopTime           datetime     default: NULL
@Events             varchar(300) default: SP-related events and errors/warnings -- Comma-delimited list specifying the events numbers to trace
@Cols               varchar(300) default: All columns -- Comma-delimited list specifying the column numbers to trace
@IncludeTextFilter  sysname      default: NULL -- String mask specifying what TextData strings to include in the trace
@ExcludeTextFilter  sysname      default: NULL -- String mask specifying what TextData strings to filter out of the trace
@IncludeObjIdFilter sysname      default: NULL -- Specifies the id of an object to target with the trace
@ExcludeObjIdFilter sysname      default: NULL -- Specifies the id of an object to exclude from the trace
@TraceId            int          default: NULL -- Specified the id of the trace to list when you specify the LIST option to @OnOff
',
@author='Ken Henderson', @email='khen@khen.com',
@version='2', @revision='0',
@datecreated='19990401', @datelastchanged='20001216',
@example='EXEC sp_start_trace -- Starts a trace
EXEC sp_start_trace @Filename=''d:\mssql7\log\mytrace'' -- Starts a trace with the specified file name
EXEC sp_start_trace @Events=''37,43'' -- Starts a trace the traps the specified event classes
EXEC sp_start_trace @Cols=''1,2,3'' -- Starts a trace that includes the specified columns
EXEC sp_start_trace @IncludeTextFilter=''EXEC% FooProc%'' -- Starts a trace that includes events matching the specified TextData mask
EXEC sp_start_trace @tracename=''General Performance'' -- Starts a trace using the specified name
EXEC sp_start_trace @filename = ''d:\mssql7\log\mytrace'', -- Starts a trace with the specified parameters
		    @TraceName = ''General Performance'',
		    @Options = 2, 
		    @MaxFileSize = 500,
		    @StopTime = NULL, 
		    @Events = ''10,11,14,15,16,17,27,37,40,41,55,58,67,69,79,80,98'',
		    @Cols = DEFAULT,
		    @IncludeTextFilter = NULL,
		    @IncludeObjIdFilter = NULL,
		    @ExcludeObjIdFilter = NULL
'
RETURN -1
GO

USE master
GO
IF OBJECT_ID('sp_stop_trace') IS NOT NULL
  DROP PROC sp_stop_trace
GO
CREATE PROC sp_stop_trace @TraceId INT = 0, @TraceName sysname='tsqltrace'
/*
Object: sp_stop_trace
Description: Stops a Profiler-like trace using Transact-SQL eXtended Procedure calls.

Usage: sp_stop_trace @TraceName sysname default: tsqltrace -- Specifies the name of the trace

Returns: (None)

$Author: Ken Henderson $. Email: khen@khen.com
@Updater Author : choi bora Email:ceusee@gmail.com Date :2007-06-05

$Revision: 2.1 $

Example: EXEC sp_stop_trace -- Stops the default trace
*/
AS
SET NOCOUNT ON

--IF @TraceName='/?' GOTO Help

-- Declare variables
DECLARE @OldQueueHandle int -- Queue handle of currently running trace queue
DECLARE @OldTraceFile sysname -- File name of running trace

IF @TraceId <> 0 
BEGIN
    EXEC sp_trace_setstatus @TraceId, 0 -- stop
    EXEC sp_trace_setstatus @TraceId, 2 -- delete
END
ELSE IF @TraceName IS NOT NULL
BEGIN

    -- Stop the trace if running
    IF OBJECT_ID('tempdb..TraceQueue') IS NOT NULL BEGIN
      IF EXISTS(SELECT * FROM tempdb..TraceQueue WHERE TraceName = @TraceName) 
	BEGIN
    
		SELECT @OldQueueHandle = TraceID, @OldTraceFile=TraceFile
		FROM tempdb..TraceQueue
		WHERE TraceName = @TraceName

	        IF @@ROWCOUNT<>0 
	        BEGIN
	          EXEC sp_trace_setstatus @traceid=@OldQueueHandle, @status=0
	          EXEC sp_trace_setstatus @traceid=@OldQueueHandle, @status=2
	          PRINT 'Deleted trace queue ' + CAST(@OldQueueHandle AS varchar(20))+'.'
	          PRINT 'The trace output file name is: '+@OldTraceFile
	          DELETE tempdb..TraceQueue WHERE TraceName = @TraceName
       	 END
       END 
	ELSE PRINT 'No active traces named '+@TraceName+'.'
    END ELSE PRINT 'No active traces.'
END
ELSE IF @TraceName IS NULL
	PRINT 'Input TraneName File Info'

RETURN 0

Help:
EXEC sp_usage @objectname='sp_stop_trace',@desc='Stops a Profiler-like trace using Transact-SQL eXtended Procedure calls.',
			@parameters='@TraceName sysname default: tsqltrace -- Specifies the name of the trace
',
@author='Ken Henderson', @email='khen@khen.com',
@version='2', @revision='0',
@datecreated='19990401', @datelastchanged='20001216',
@example='EXEC sp_stop_trace -- Stops the default trace
'
RETURN -1
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.sp_tmpregenumvalues 
  @hive varchar (40), @key nvarchar (2000), @direct_output int = 0
AS
DECLARE @sql70or80xp sysname
DECLARE @sqlcmd nvarchar (4000)
CREATE TABLE #regdata (RegValue nvarchar(190), RegData nvarchar (1800))
IF CHARINDEX ('7.00.', @@VERSION) = 0
  SET @sql70or80xp = 'master.dbo.xp_instance_regenumvalues'
ELSE
  SET @sql70or80xp = 'master.dbo.xp_regenumvalues'
IF @direct_output = 1 SET @sqlcmd = 'EXEC '
ELSE SET @sqlcmd = 'INSERT INTO #regdata EXEC '
SET @sqlcmd = @sqlcmd + @sql70or80xp + ' @P1, @P2' 
EXEC sp_executesql @sqlcmd, 
  N'@P1 varchar (40), @P2 nvarchar (2000)', 
  @hive, @key
IF @direct_output = 0 SELECT * FROM #regdata

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
-- Create temporary stored procedures in tempdb 
CREATE PROCEDURE dbo.sp_tmpregread 
  @hive varchar (60), @key nvarchar (2000), @value nvarchar (2000), @data nvarchar (4000) = NULL OUTPUT 
AS
DECLARE @sql70or80xp sysname

DECLARE @sqlcmd nvarchar (4000)
-- To avoid osql line wrapping, don't store more than 2000 chars.
CREATE TABLE #regdata (RegValue nvarchar(190), RegData nvarchar (1800))
IF CHARINDEX ('7.00.', @@VERSION) = 0
  SET @sql70or80xp = 'master.dbo.xp_instance_regread'
ELSE
  SET @sql70or80xp = 'master.dbo.xp_regread'
SET @sqlcmd = 'INSERT INTO #regdata EXEC ' + @sql70or80xp + ' @P1, @P2, @P3' 
EXEC sp_executesql @sqlcmd, 
  N'@P1 varchar (40), @P2 nvarchar (2000), @P3 nvarchar (2000)', 
  @hive, @key, @value 
SELECT * FROM #regdata
PRINT ''

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/*************************************************************************  
* 프로시저명  : dbo.sp_top5locks
* 작성정보    : 2007-08-11 김태환
* 관련페이지  :  
* 내용        :
* 수정정보    : lock을 많이 잡고 있는 TOP 5 프로세스 
**************************************************************************/
CREATE PROCEDURE dbo.sp_top5locks
	@iCount		smallint = 5
AS 
	set nocount on
	set transaction isolation level read uncommitted 

	SELECT 
		'KILL ' + CAST(lock.request_session_id as varchar(5)) as 'KILL'
	,	ca.text as SQL_TEXT
	,	ses.host_name as HOST
	,   datediff(mi, ses.login_time, getdate()) AS '실행시간'
	,	ses.program_name as program_name
	,   ses.login_name
	,	DB_NAME(req.database_id) as user_db_name
	,   ses.client_version
	,	con.client_net_address
	FROM
	(
		select top (@iCount) request_session_id  , count(request_session_id) as cnt
		from sys.dm_tran_locks with(nolock)
		where request_session_id > 50
		group by request_session_id
		order by cnt desc
	)as lock
	inner join sys.dm_exec_requests as req with (nolock) on lock.request_session_id = req.session_id
	inner join sys.dm_exec_sessions as ses with (nolock) on req.session_id = ses.session_id
	inner join sys.dm_exec_connections as con with (nolock) on ses.session_id = con.session_id
	cross apply sys.dm_exec_sql_text (req.sql_handle) as ca

	set nocount off
go

/*
	작성자 : DB개발팀 권병준
	작성일 : 2007-08-19
	Usage :
	
	-- 대기 수집
	EXECUTE DBO.TRACK_WAITSTATS @NUM_SAMPLES=6 ,@DELAY_INTERVAL=30 ,@DELAY_TYPE='S' ,@TRUNCATE_HISTORY='Y' ,@CLEAR_WAITSTATS='Y'	

	-- 수집된 대기 조회
	EXECUTE DBO.BJ_GET_WAITSTATS
*/

CREATE PROC DBO.SP_TRACK_WAITSTATS 
	(@NUM_SAMPLES INT=4, 
	@DELAY_INTERVAL INT=15, 
	@DELAY_TYPE NVARCHAR(10)='S', 
	@TRUNCATE_HISTORY NVARCHAR(1)='Y', 
	@CLEAR_WAITSTATS NVARCHAR(1)='Y') 
AS 

-- THIS STORED PROCEDURE IS PROVIDED "AS IS" WITH NO WARRANTIES, AND 
-- CONFERS NO RIGHTS. 
-- USE OF INCLUDED SCRIPT SAMPLES ARE SUBJECT TO THE TERMS SPECIFIED AT 
-- HTTP://WWW.MICROSOFT.COM/INFO/CPYRIGHT.HTM 
-- 
-- T. DAVIDSON 
-- @NUM_SAMPLES IS THE NUMBER OF TIMES TO CAPTURE WAITSTATS, DEFAULT IS 10 
-- TIMES -- DEFAULT DELAY INTERVAL IS 1 MINUTE 
-- DELAYNUM IS THE DELAY INTERVAL - CAN BE MINUTES OR SECONDS 
-- DELAYTYPE SPECIFIES WHETHER THE DELAY INTERVAL IS MINUTES OR SECONDS 
-- CREATE WAITSTATS TABLE IF IT DOESN'T EXIST, OTHERWISE TRUNCATE 
-- REVISION: 4/19/05 
--- (1) ADDED OBJECT OWNER QUALIFIER
--- (2) OPTIONAL PARAMETERS TO TRUNCATE HISTORY AND CLEAR WAITSTATS 

SET NOCOUNT ON 

/*IF NOT EXISTS 	(SELECT 
			1 
		FROM 
			SYS.OBJECTS 
		WHERE 
			OBJECT_ID = OBJECT_ID ( N'[DBA].[DBO].[BJ_WAITSTATS]') AND 
			OBJECTPROPERTY(OBJECT_ID, N'ISUSERTABLE') = 1) 
	CREATE TABLE [DBA].[DBO].[BJ_WAITSTATS] 
	(
		[WAIT_TYPE] NVARCHAR(60) NOT NULL, 
		[WAITING_TASKS_COUNT] BIGINT NOT NULL, 
		[WAIT_TIME_MS] BIGINT NOT NULL, 
		[MAX_WAIT_TIME_MS] BIGINT NOT NULL, 
		[SIGNAL_WAIT_TIME_MS] BIGINT NOT NULL, 
		[NOW] DATETIME NOT NULL DEFAULT GETDATE()
	) 
*/

IF LOWER(@TRUNCATE_HISTORY) NOT IN (N'Y',N'N') 
BEGIN 
	RAISERROR ('VALID @TRUNCATE_HISTORY VALUES ARE ''Y'' OR ''N''',16,1) WITH NOWAIT 
END 

IF LOWER(@CLEAR_WAITSTATS) NOT IN (N'Y',N'N') 
BEGIN 
	RAISERROR ('VALID @CLEAR_WAITSTATS VALUES ARE ''Y'' OR ''N''',16,1) WITH NOWAIT 
END 

IF LOWER(@TRUNCATE_HISTORY) = N'Y' 
	TRUNCATE TABLE DBA.DBO.BJ_WAITSTATS 

-- CLEAR OUT BJ_WAITSTATS
IF LOWER (@CLEAR_WAITSTATS) = N'Y' 
	DBCC SQLPERF ([SYS.DM_OS_WAIT_STATS],CLEAR) WITH NO_INFOMSGS 

DECLARE	@I INT,
		@DELAY VARCHAR(8), 
		@DT VARCHAR(3), 
		@NOW DATETIME, 
		@TOTALWAIT NUMERIC(20,1), 
		@ENDTIME DATETIME, 
		@BEGINTIME DATETIME, 
		@HR INT, @MIN INT, 
		@SEC INT 

SELECT 
	@I = 1 
SELECT 
	@DT = CASE LOWER(@DELAY_TYPE) 
		WHEN N'MINUTES' THEN 'M' 
		WHEN N'MINUTE' THEN 'M' 
		WHEN N'MIN' THEN 'M' 
		WHEN N'MI' THEN 'M' 
		WHEN N'N' THEN 'M' 
		WHEN N'M' THEN 'M' 
		WHEN N'SECONDS' THEN 'S' 
		WHEN N'SECOND' THEN 'S' 
		WHEN N'SEC' THEN 'S' 
		WHEN N'SS' THEN 'S' 
		WHEN N'S' THEN 'S' 
		ELSE @DELAY_TYPE 
	END 

IF @DT NOT IN ('S','M') 
BEGIN 
	RAISERROR ('DELAY TYPE MUST BE EITHER ''SECONDS'' OR ''MINUTES''',16,1) WITH NOWAIT 
	RETURN 
END 

IF @DT = 'S' 
BEGIN 
	SELECT 
		@SEC = @DELAY_INTERVAL % 60, 
		@MIN = CAST((@DELAY_INTERVAL / 60) AS INT), 
		@HR = CAST((@MIN / 60) AS INT) 
END 

IF @DT = 'M' 
BEGIN 
	SELECT 
		@SEC = 0, 
		@MIN = @DELAY_INTERVAL % 60, 
		@HR = CAST((@DELAY_INTERVAL / 60) AS INT) 
END 

SELECT 
	@DELAY= RIGHT('0'+ CONVERT(VARCHAR(2),@HR),2) + ':' + + RIGHT('0'+CONVERT(VARCHAR(2),@MIN),2) + ':' + + RIGHT('0'+CONVERT(VARCHAR(2),@SEC),2) 

IF @HR > 23 OR @MIN > 59 OR @SEC > 59 
BEGIN 
	SELECT '
		DELAY INTERVAL AND TYPE: ' + CONVERT (VARCHAR(10),@DELAY_INTERVAL) + ',' + @DELAY_TYPE + ' CONVERTS TO ' + @DELAY 
	RAISERROR ('HH:MM:SS DELAY TIME CANNOT > 23:59:59',16,1) WITH NOWAIT 
	RETURN 
END 

WHILE (@I <= @NUM_SAMPLES) 
BEGIN
	SELECT 
		@NOW = GETDATE() 

	INSERT INTO [DBA].[DBO].[BJ_WAITSTATS]
	(
		[WAIT_TYPE], 
		[WAITING_TASKS_COUNT], 
		[WAIT_TIME_MS], 
		[MAX_WAIT_TIME_MS], 
		[SIGNAL_WAIT_TIME_MS], 
		[NOW]
	)
	 SELECT 
		[WAIT_TYPE], 
		[WAITING_TASKS_COUNT], 
		[WAIT_TIME_MS], 
		[MAX_WAIT_TIME_MS], 
		[SIGNAL_WAIT_TIME_MS], 
		@NOW 
	FROM 
		SYS.DM_OS_WAIT_STATS 

	INSERT INTO [DBA].[DBO].[BJ_WAITSTATS]
	(
		[WAIT_TYPE], 
		[WAITING_TASKS_COUNT], 
		[WAIT_TIME_MS], 
		[MAX_WAIT_TIME_MS], 
		[SIGNAL_WAIT_TIME_MS], 
		[NOW]
	) 
	SELECT 
		'TOTAL', 
		SUM([WAITING_TASKS_COUNT]), 
		SUM([WAIT_TIME_MS]), 
		0, 
		SUM([SIGNAL_WAIT_TIME_MS]), 
		@NOW 
	FROM 
		[DBA].[DBO].[BJ_WAITSTATS] 
	WHERE 
		[NOW] = @NOW 

	SELECT 
		@I = @I + 1 
	
	WAITFOR DELAY @DELAY 

END 
go
/**************************************************************************************************************  
SP    명 : master.dbo.sp_who3
작성정보: 2004-12-13 양은선
관련페이지 :
내용	    : 정원혁 강사님 교육받고...
지난 2초간 가장 CPU를 많이사용한 프로세스를 보여준다.
===============================================================================
				수정정보 
===============================================================================
2006-4-12 박노철 inputbuffer 도 함께 나오도록 수정
**************************************************************************************************************/ 
CREATE proc sp_who4
 @res_count int = 15
,@bactive	bit	= 1
as

SET NOCOUNT ON
SET LOCK_TIMEOUT 10000
SET ANSI_WARNINGS OFF

create table #cpu_usage
(
	seq int identity primary key
,	cpu int
,	spid int
,	kpid int
,	inputbuffer varchar(3000)
)

create table #inputbuffer
(
	seq int identity primary key
,	eventtype char(50)
,	parameters int
,	eventinfo varchar(max)
)

declare @rowcount int
	,	@iid int

set @rowcount = 0
set @iid = 0

insert #cpu_usage (cpu, spid, kpid)
select cpu ,spid, kpid from master..sysprocesses 
where spid > 50

select @rowcount = @@rowcount , @iid = scope_identity()

while(@rowcount > 0) begin
	declare @buf_str varchar(40)
	select @buf_str  = 'dbcc inputbuffer(' + cast(spid as varchar) + ')' from #cpu_usage with(nolock) where seq = @iid

	insert into #inputbuffer (EventType, Parameters, EventInfo)
	exec(@buf_str)

	if(@@rowcount > 0) begin	
		declare @inputbuf varchar(3000)
		select top 1 @inputbuf = substring(eventinfo,1,3000) from #inputbuffer order by seq desc
		update #cpu_usage set inputbuffer = @inputbuf where seq=@iid 
	end

	set @iid = @iid - 1
	set @rowcount = @rowcount - 1	
end	


PRINT 'waiting for 2 seconds...'
WAITFOR DELAY '0:00:02'

IF @bactive = 0 
	SELECT TOP(@res_count) u.inputbuffer AS inputBufferStr, p.spid, p.cpu - u.cpu AS 'CPU변화', p.cpu, p.physical_io, CAST (p.hostname AS VARCHAR(20)) AS hostname
		, p.last_batch, p.program_name,p.loginame 
	FROM master..sysprocesses p JOIN #cpu_usage u ON p.spid = u.spid and p.kpid = u.kpid
	ORDER BY CPU변화 DESC, p.cpu DESC 
ELSE
	SELECT TOP(@res_count) u.inputbuffer  AS inputBufferStr, p.spid, p.cpu - u.cpu AS 'CPU변화', p.cpu, p.physical_io, CAST (p.hostname AS VARCHAR(20)) AS hostname
		, p.last_batch, p.program_name,p.loginame 
	FROM master..sysprocesses p JOIN #cpu_usage u ON p.spid = u.spid and p.kpid = u.kpid
	WHERE p.cpu - u.cpu > 0 
	ORDER BY CPU변화 DESC, p.cpu DESC 
go

-------------------------------------------------------------------------------------------------------
-- OBJECT NAME		: sp_who_4
-- AUTHOR		: Mike A. Barzilli
-- AUTHOR EMAIL		: mike@barzilli.com
-- DATE			: 09/04/2002
--
-- INPUTS		: @run_mode, @spid, @login, @host, @db, @program,
--			: @status, @command, @blk, @wait, @trans, @cpu, @dsk,
--			: @last_batch, @o
--
-- OUTPUTS		: rows from sv_sysprocesses
--
-- DEPENDENCIES		: master.dbo.sv_sysprocesses view, master.dbo.sv_block view,
--			: master.dbo.fn_view_input_buffer function
--
-- DESCRIPTION		:
-- This procedure will return a list of processes that are running on the SQL Server. This
-- procedure was written to avoid using sp_who, sp_who2, sp_lock, sp_lockinfo, and dbcc
-- inputbuffer. It has various input parameters to control filtering and ordering of the
-- results. It also provides 6 different run modes. Use @run_mode of "help" for more details.
--
-- When one of the "input" run modes is used, it creates an SQLDMO object that is passed
-- to a function. It opens a trusted connection (using the SQL Service Account) to the
-- local server. Once complete, it closes the SQLDMO object. sp_who_3 only works with SQL
-- 2000 SP3 or higher. This procedure is normally called from Query Analyzer by DBAs.
--
-- MODIFICATION HISTORY	:
-------------------------------------------------------------------------------------------------------
-- 09/04/2002 - Mike A. Barzilli
-- Created procedure.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CREATE PROC dbo.sp_who_4
	@run_mode NVARCHAR(12) = NULL,
	@spid NVARCHAR(50) = NULL,
	@login NVARCHAR(50) = NULL,
	@host NVARCHAR(50) = NULL,
	@db NVARCHAR(50) = NULL,
	@program NVARCHAR(50) = NULL,
	@status NVARCHAR(50) = NULL,
	@command NVARCHAR(50) = NULL,
	@blk NVARCHAR(50) = NULL,
	@wait NVARCHAR(50) = NULL,
	@trans NVARCHAR(50) = NULL,
	@cpu NVARCHAR(50) = NULL,
	@dsk NVARCHAR(50) = NULL,
	@last_batch NVARCHAR(100) = NULL,
	@o NVARCHAR(100) = NULL AS

-------------------------------------------------------------------------------------------------------
-- Setup all initial input parameters, perform parameter validation, and setup default values.
-------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET IMPLICIT_TRANSACTIONS OFF
DECLARE
	@select_statement NVARCHAR(2000),
	@server_object_id INT,
	@error_code INT

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that are text strings.
-------------------------------------------------------------------------------------------------------
SELECT
	@login = REPLACE(@login, '''', N''''''),
	@host = REPLACE(@host, '''', N''''''),
	@db = REPLACE(@db, '''', N''''''),
	@program = REPLACE(@program, '''', N''''''),
	@status = REPLACE(@status, '''', N''''''),
	@command = REPLACE(@command, '''', N''''''),
	@wait = REPLACE(@wait, '''', N'''''')

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that are numeric fields which allow less than/greater than searches.
-------------------------------------------------------------------------------------------------------
SELECT
	@spid = CASE
			WHEN @spid IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @spid) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@spid) = 1
				THEN N'= ' + @spid
			WHEN LTRIM(RTRIM(SUBSTRING(@spid, 0, PATINDEX('%[0123456789]%', @spid))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@spid, PATINDEX('%[0123456789]%', @spid), 50)) = 1
				THEN @spid
			ELSE N'error'
		END,
	@blk = CASE
			WHEN @blk IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @blk) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@blk) = 1
				THEN N'= ' + @blk
			WHEN LTRIM(RTRIM(SUBSTRING(@blk, 0, PATINDEX('%[0123456789]%', @blk))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@blk, PATINDEX('%[0123456789]%', @blk), 50)) = 1
				THEN @blk
			ELSE N'error'
		END,
	@trans = CASE
			WHEN @trans IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @trans) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@trans) = 1
				THEN N'= ' + @trans
			WHEN LTRIM(RTRIM(SUBSTRING(@trans, 0, PATINDEX('%[0123456789]%', @trans))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@trans, PATINDEX('%[0123456789]%', @trans), 50)) = 1
				THEN @trans
			ELSE N'error'
		END,
	@cpu = CASE
			WHEN @cpu IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @cpu) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@cpu) = 1
				THEN N'= ' + @cpu
			WHEN LTRIM(RTRIM(SUBSTRING(@cpu, 0, PATINDEX('%[0123456789]%', @cpu))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@cpu, PATINDEX('%[0123456789]%', @cpu), 50)) = 1
				THEN @cpu
			ELSE N'error'
		END,
	@dsk = CASE
			WHEN @dsk IS NULL
				THEN NULL
			WHEN PATINDEX('%[-/*;''"]%', @dsk) >= 1
				THEN N'error'
			WHEN ISNUMERIC(@dsk) = 1
				THEN N'= ' + @dsk
			WHEN LTRIM(RTRIM(SUBSTRING(@dsk, 0, PATINDEX('%[0123456789]%', @dsk))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISNUMERIC(SUBSTRING(@dsk, PATINDEX('%[0123456789]%', @dsk), 50)) = 1
				THEN @dsk
			ELSE N'error'
		END

-------------------------------------------------------------------------------------------------------
-- Initialize input parameters that require custom handling.
-------------------------------------------------------------------------------------------------------
SELECT
	@run_mode = CASE
			WHEN LOWER(@run_mode) = 'input active'
				THEN 'active input'
			WHEN LOWER(@run_mode) = 'input block'
				THEN 'block input'
			ELSE LOWER(ISNULL(@run_mode, N'normal'))
		END,
	@last_batch = CASE
			WHEN @last_batch IS NULL
				THEN NULL
			WHEN PATINDEX('%[-*;''"]%', @last_batch) >= 1
					OR DATALENGTH(@last_batch) > 100
				THEN N'error'
			WHEN ISDATE(@last_batch) = 1
				THEN N'= CAST(''' + @last_batch + ''' AS DATETIME)'
			WHEN LTRIM(RTRIM(SUBSTRING(@last_batch, 0, PATINDEX('%[0123456789]%', @last_batch))))
					IN ('=', '<>', '!=', '>', '<', '>=', '!<', '<=', '!>')
					AND ISDATE(SUBSTRING(@last_batch, PATINDEX('%[0123456789]%', @last_batch), 50)) = 1
				THEN SUBSTRING(@last_batch, 0, PATINDEX('%[0123456789]%', @last_batch)) +
					'CAST(''' + SUBSTRING(@last_batch, PATINDEX('%[0123456789]%', @last_batch), 50) + ''' AS DATETIME)'
			ELSE N'error'
		END,
	@o = CASE
 			WHEN @o IS NULL
 				THEN N' ORDER BY SPID ASC'
			WHEN PATINDEX('%[-/*;''"]%', @o) >= 1
					OR LOWER(@o) LIKE '%order%'
					OR DATALENGTH(@o) > 100
				THEN N'error'
			ELSE N' ORDER BY ' + @o + N', ''a'' ASC'
		END,
	@error_code = 0

-------------------------------------------------------------------------------------------------------
-- Validate the @o parameter (order by clause) and prevent any malicious code injection.
-------------------------------------------------------------------------------------------------------
IF @o <> 'error'
	BEGIN
		SET @select_statement = N'SET NOEXEC ON  SELECT cast(SPID as int), Login, Host, DB, Program, Status, Command, Blk, Wait, Trans, CPU, Dsk, Last_Batch, ' +
			CASE
				WHEN @run_mode IN ('input', 'active input', 'block input')
					THEN '0 AS Input_Buffer, SP2 '
				ELSE 'exec dba.dbo.up_DBA_dbccinputbuffer(SP2)'
			END +
			'FROM master.dbo.sv_sysprocesses' + @o + N'  SET NOEXEC OFF'

		EXEC @error_code = sp_executesql @select_statement

		SELECT @o = N'error', @error_code = 1
			WHERE @error_code <> 0
	END

-------------------------------------------------------------------------------------------------------
-- Check for any errors and raise them now.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN ('input', 'active input', 'block input')
		AND IS_SRVROLEMEMBER('processadmin') = 0
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(15003, -1, -1, 'sysadmin or processadmin')
	END

IF @run_mode NOT IN ('normal', 'active', 'input', 'block', 'active input', 'block input', 'help', '?')
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@run_mode', '"normal", "active", "input", "block", "active input", "block input", and "help"')
	END

IF @@TRANCOUNT > 0
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(15002, -1, -1, 'sp_who_3')
	END

IF @spid = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@spid', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @blk = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@blk', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @trans = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@trans', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @cpu = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@cpu', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @dsk = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@dsk', 'Comparison Operators and Numbers following the procedure''s rules')
	END

IF @last_batch = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@last_batch', 'Comparison Operators and a valid date following the procedure''s rules (up to 50 characters)')
	END

IF @o = 'error'
	BEGIN
		SELECT @run_mode = N'help', @error_code = 1
		RAISERROR(14266, -1, -1, '@o', 'Columns to be used in the order by clause (up to 50 characters)')
	END

-------------------------------------------------------------------------------------------------------
-- Create the portion of the SELECT clause with the list of columns and the FROM clause.
-------------------------------------------------------------------------------------------------------
SET @select_statement = N'SELECT cast(SPID as int), Login, Host, DB, Program, Status, Command, Blk, Wait, Trans, CPU, Dsk, Last_Batch, ' +
	CASE
		WHEN @run_mode IN ('input', 'active input', 'block input')
			THEN N'CASE
					WHEN SPID < 51 OR SPID <> SP2
						THEN ''.''
					ELSE fn_view_input_buffer(@server_object_id, SP2, sql_handle)
				END AS Input_Buffer, '
		ELSE N''
	END +
	N'SP2 FROM master.dbo.sv_sysprocesses WITH (NOLOCK) '

-------------------------------------------------------------------------------------------------------
-- Create the portion of the WHERE clause and apply all filter parameters passed in or by run mode.
-------------------------------------------------------------------------------------------------------
SET @select_statement = @select_statement +
	CASE
		WHEN @run_mode IN ('normal', 'input')
			THEN N'WHERE' +
				CASE
					WHEN @spid IS NULL
						THEN N''
					WHEN @spid LIKE '%.%'
						THEN N' SPID ' + @spid + N' AND '
					ELSE N' SP2 ' + @spid + N' AND '
				END +
				ISNULL(N' Login LIKE ''' + @login + N''' AND ', '') +
				ISNULL(N' Host LIKE ''' + @host + N''' AND ', '') +
				ISNULL(N' DB LIKE ''' + @db + N''' AND ', '') +
				ISNULL(N' Program LIKE ''' + @program + N''' AND ', '') +
				ISNULL(N' Status LIKE ''' + @status + N''' AND ', '') +
				ISNULL(N' Command LIKE ''' + @command + N''' AND ', '') +
				ISNULL(N' REPLACE(Blk, ''.'', N''0'') ' + @blk + N' AND ', '') +
				ISNULL(N' Wait LIKE ''' + @wait + N''' AND ', '') +
				ISNULL(N' REPLACE(Trans, ''.'', N''0'') ' + @trans + N' AND ', '') +
				ISNULL(N' CPU ' + @cpu + N' AND ', '') +
				ISNULL(N' Dsk ' + @dsk + N' AND ', '') +
				ISNULL(N' Last_Batch ' + @last_batch + N' AND ', '')

		WHEN @run_mode IN ('active', 'active input')
			THEN N'WHERE Status NOT IN (''sleeping'', ''BACKGROUND'')
				OR (Command <> ''AWAITING COMMAND''
					AND SP2 > 50)
				OR Blk <> ''.''
				OR Wait <> ''.''
				OR Trans <> ''.'''

		ELSE N'LEFT OUTER JOIN sv_block WITH (NOLOCK)
				ON sv_sysprocesses.SP2 = sv_block.blocked
			WHERE sv_block.blocked IS NOT NULL
				OR Blk <> ''.'''
	END

-------------------------------------------------------------------------------------------------------
-- Create the portion of the ORDER BY clause and remove and leftovers from the WHERE clause.
-------------------------------------------------------------------------------------------------------
SET @select_statement =
	CASE
		WHEN @run_mode IN ('normal', 'input')
			THEN LEFT(@select_statement, (DATALENGTH(@select_statement)/2) - 5) + @o
		ELSE @select_statement + @o
	END

-------------------------------------------------------------------------------------------------------
-- If using one of the "input" run modes then do these steps:
-- 1.) Create and open the SQLDMO connection. Then run the dynamic SELECT statement created earlier.
-- 2.) Close and destroy the SQLDMO connection created in step 1.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'input', N'active input', N'block input')
	BEGIN
		EXEC master.dbo.sp_OACreate 'sqldmo.sqlserver', @server_object_id OUT
		EXEC master.dbo.sp_OASetProperty @server_object_id, 'loginsecure', 'true'
		EXEC master.dbo.sp_OASetProperty @server_object_id, 'applicationname', 'sp_who_3 Input Buffers'
		EXEC master.dbo.sp_OAMethod @server_object_id, 'connect', null, @@SERVERNAME
		EXEC master.dbo.sp_executesql @select_statement, N'@server_object_id INT', @server_object_id
		EXEC master.dbo.sp_OAMethod @server_object_id, 'disconnect'
		EXEC master.dbo.sp_OADestroy @server_object_id
	END

-------------------------------------------------------------------------------------------------------
-- If Not using one of the "input" run modes then only run the dynamic SELECT statement created earlier.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'normal', N'active', N'block')
	BEGIN
		EXEC master.dbo.sp_executesql @select_statement
	END

-------------------------------------------------------------------------------------------------------
-- Display the help section if the run mode specified is "help" or any errors were encountered.
-------------------------------------------------------------------------------------------------------
IF @run_mode IN (N'help', N'?')
	BEGIN
		PRINT ('
AUTHOR			: Mike A. Barzilli
AUTHOR EMAIL		: mike@barzilli.com

sp_who_3:
	Provides information about current SQL Server processes. The results can be filtered and sorted
	in many ways. It has 6 run modes which filter the information to specific needs.

	This procedure was written to avoid using sp_who, sp_who2, sp_lock, sp_lockinfo, and dbcc
	inputbuffer. Those procedures are not flexible and hang if tempdb is itself locked. sp_who_3
	returns the results without any performance or lock compromising steps such as temp tables,
	cursors, table parameters, or any locks. sp_who_3 only works with SQL Server 2000 Service Pack
	3 or higher. sp_who_3 is best viewed in grid mode.

Syntax:
	EXEC sp_who_3 [ [ @run_mode = ] ''run mode'' ]
		[ , [ @spid = ] ''SPID'' ]
		[ , [ @login = ] ''login name'' ]
		[ , [ @host = ] ''host name'' ]
		[ , [ @db = ] ''database name'' ]
		[ , [ @program = ] ''program name'' ]
		[ , [ @status = ] ''status'' ]
		[ , [ @command = ] ''command'' ]
		[ , [ @blk = ] ''blocking SPID'' ]
		[ , [ @wait = ] ''wait type and wait time (msecs)'' ]
		[ , [ @trans = ] ''open transactions'' ]
		[ , [ @cpu = ] ''CPU time usage'' ]
		[ , [ @dsk = ] ''disk usage'' ]
		[ , [ @last_batch = ] ''last batch date and time'' ]
		[ , [ @o = ] ''order by clause'' ]

Arguments:
	[ @run_mode = ] ''run_mode''
		Is the mode to use. @run_mode is NVARCHAR(12), with a default of "normal". Valid values
		are: "normal", "active", "input", "block", "active input", "block input", and "help".
		When using "active", "block", "active input", or "block input", any filters specified
		are ignored. Sort order can always be specified.

		A run mode of "normal" returns all current connections and those results are filtered
		by all 13 filter parameters if any filter conditions are specified.

		Run mode "active" returns only active connections or ones with open transactions. All
		filter parameters are ignored.

		Run mode "input" is similar to "normal" but it also returns the input buffer. Only
		sysadmin or processadmin members can use this mode. This mode creates an SQLDMO object
		that is passed to a function. It opens a trusted connection (using the SQL Service
		Account) to the local server. Once complete, it closes the SQLDMO object. Using
		sp_oacreate is not recommended because it runs in-processes, wastes resources, and may
		crash the server if errors occur. These risks are minimized because only built-in Tools
		objects are used. The results are filtered by all 13 filter parameters if specified.

		Run mode "block" returns only connections that are either being blocked or are blocking
		other processes. All filter parameters are ignored.

		Run mode "active input" combines "active" and "input" modes. It returns active
		connections with input buffers. Only sysadmin or processadmin members can use this
		mode. The same "input" function is used. All filter parameters are ignored.

		Run mode "block input" combines "block" and "input" modes. It returns blocked
		connections with input buffers. Only sysadmin or processadmin members can use this
		mode. The same "input" function is used. All filter parameters are ignored.

		Run mode "help" only returns information about how to use sp_who_3.

	[ @spid = ] ''SPID''
		Is the SPID used to filter the results. @spid is DECIMAL(7,2), with a default of NULL.
		The input parameter @spid is NVARCHAR(50) to allow Comparison Operators ("=", "<>",
		"!=", ">", "<", ">=", "!<", "<=", "!>") to be specified. This is one of 13 possible
		filters. For all numerical filters, if a Comparison Operator is not specified and only
		a numerical value is passed in, sp_who_3 defaults to an equal comparison. When using
		the @spid filter on SPIDs that have multiple ECIDs {.00, .01, ...n}, use a whole
		number SPID (I.E. 1, 2, etc...) to return the SPIDs and all their sub-threads. If a
		decimal is used instead (I.E. 1.00, 2.01, etc...), only SPIDs matching both the SPID
		and ECID portions are returned. All filters are ignored when run_mode is "active",
		"block", "active input", or "block input".

	[ @login = ] ''login name''
		Is the login name used to filter the results. @login is NVARCHAR(25), with a default of
		NULL. The input parameter @login is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		"[]", "[n-n]", "[^]") to be specified. @login and all non-numeric filters will get
		Search Predicate (such as "=" or the keyword "LIKE") added to them internally. Do not
		include Search Predicates in these parameters.

	[ @host = ] ''host name''
		Is the host name used to filter the results. @host is NVARCHAR(12), with a default of
		NULL. The input parameter @host is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		etc...) to be specified.

	[ @db = ] ''database name''
		Is the database name used to filter the results. @db is NVARCHAR(25), with a default of
		NULL. The input parameter @db is NVARCHAR(50) to allow Wildcard Operators ("%", "_",
		etc...) to be specified.

	[ @program = ] ''program name''
		Is the program name used to filter the results. @program is NVARCHAR(25), with a
		default of NULL. The input parameter @program is NVARCHAR(50) to allow Wildcard
		Operators ("%", "_", etc...) to be specified.

	[ @status = ] ''status''
		Is the status used to filter the results. @status is NVARCHAR(12), with a default of
		NULL. The input parameter @status is NVARCHAR(50) to allow Wildcard Operators ("%",
		"_", etc...) to be specified.

	[ @command = ] ''command''
		Is the command used to filter the results. @command is NVARCHAR(16), with a default of
		NULL. The input parameter @command is NVARCHAR(50) to allow Wildcard Operators ("%",
		"_", etc...) to be specified.

	[ @blk = ] ''blocking SPID''
		Is the "blocking SPID" used to filter the results. @blk is SMALLINT, with a default of
		NULL. The input parameter @blk is NVARCHAR(50) to allow Comparison Operators ("<", ">",
		etc...) to be specified. The [Blk] column substitutes "." instead of zero for display.
		However, in the @blk filter parameter, use a input a "0" to find SPIDs with no blocks.

	[ @wait = ] ''wait type and wait time (msecs)''
		Is the wait type and wait time (msecs) used to filter the results. @wait is
		NVARCHAR(45), with a default of NULL. The input parameter @wait is NVARCHAR(50) to
		allow Wildcard Operators ("%", "_", etc...) to be specified.

	[ @trans = ] ''open transactions''
		Is the number of open transactions used to filter the results. @trans is SMALLINT, with
		a default of NULL. The input parameter @trans is NVARCHAR(50) to allow Comparison
		Operators ("<", ">", etc...) to be specified. The [Trans] column substitutes "."
		instead of zero for display. However, in the @trans filter parameter, use a input a "0"
		to find	SPIDs with no transactions.

	[ @cpu = ] ''CPU time usage''
		Is the CPU time usage (msecs) a SPID has used that is used to filter the results. @cpu
		is INT, with a default of NULL. The input parameter @cpu is NVARCHAR(50) to allow
		Comparison Operators ("<", ">", etc...) to be specified.')

		PRINT ('
	[ @dsk = ] ''disk usage''
		Is the number of disk reads and writes a SPID has used that is used to filter the
		results. @dsk is INT, with a default of NULL. The input parameter @dsk is NVARCHAR(50)
		to allow Comparison Operators ("<", ">", etc...) to be specified.

	[ @last_batch = ] ''last batch date and time''
		Is the last batch time used to filter the results. @last_batch is DATETIME, with a
		default of NULL. The input parameter @last_batch is NVARCHAR(50) to allow Comparison
		Operators ("<", ">", etc...) to be specified. Do not include quotes inside the
		parameter (I.E. @last_batch = ''> ''01/01/01''''). Here is a valid example of the
		last_batch parameter (@last_batch = ''<= 01/01/01'').

	[ @o = ] ''order by clause''
		Is the order by clause used to sort the results. @o is NVARCHAR(50), with a default of
		NULL. The input parameter @o cannot exceed NVARCHAR(50). @o is used to specify an
		order by clause the same way as for a normal select statement.

Return Code Values:
	0 (success) or 1 (failure).

Result Set:
	sp_who_3 returns a result set with the following information:

	Column		Data type	Description
	--
	[SPID]		DECIMAL(7,2)	The process ID (SPID) and execution context ID (ECID). ECID =
					{.00, .01, ...n}, where .00 is the parent thread, and {.01,
					.02, ...n} represent any sub-threads.
	--
	[Login]		NVARCHAR(25)	The login name associated with the particular process.
	--
	[Host]		NVARCHAR(12)	The host computer name associated with the process.
	--
	[DB]		NVARCHAR(25)	The database currently in use by the process.
	--
	[Program]	NVARCHAR(25)	The name of the program connecting to the SQL Server.
	--
	[Status]	NVARCHAR(12)	The process status (I.E. "sleeping", "RUNNABLE", etc...). See
					remarks for a complete list and descriptions.
	--
	[Command]	NVARCHAR(16)	The command currently executing for the process (I.E.
					"AWAITING COMMAND", "SELECT", etc...).
	--
	[Blk]		SMALLINT	The process ID for the blocking process, if one exists.
	--
	[Wait]		NVARCHAR(45)	The current wait type (I.E. "LCK_M_S", "LCK_U", etc...)
					followed by the current wait time (msecs) in parenthesis. See
					remarks for a complete list and descriptions.
	--
	[Trans]		SMALLINT	The number of open transactions for the process.
	--
	[CPU]		INT		The cumulative CPU time (msecs) for the process.
	--
	[Dsk]		BIGINT		The cumulative number of disk reads and writes for the SPID.
	--
	[Last_Batch]	DATETIME	The last date and time the process executed a command.
	--
	[Input_Buffer]	VARCHAR(8000)	The last SQL command the process executed. This only contains
					the first 255 characters unless the SPID was actively executing
					when sp_who_3 was run. This column only exists with run modes
					of "input", "active input", and "block input".
	--
	[SP2]		SMALLINT	The process ID repeated without the ECID for easy reading.
	----------------

	The sp_who_3 results default to sorted by SPID then ECID ascending. In the case of parallel
	processing, sub-thread SPIDs are created. The main thread is indicated as SPID = x.00 where
	ECID is the two digits after the decimal. Other sub-threads have the same SPID with ECID > 00.
	The [Blk] and [Trans] columns substitute "." instead of zero for display in the result set.
	However, in the @blk and @trans filter parameters, use a input a "0" to filter results.

Remarks:
	SQL Server 2000 reserves SPID values of 1 to 50 for internal use, SPID values 51 and higher are
	for user sessions. The input buffer of SPIDs less than 51 is not available. When using run
	modes that return the input buffers, the results will take longer.

	In SQL Server 2000, all orphaned DTC transactions are assigned the SPID value of "-2". Orphaned
	DTC transactions are distributed transactions that are not associated with any SPID. Thus, when
	an orphaned transaction is blocking another process, this orphaned distributed transaction can
	be identified by its distinctive "-2" SPID value. For more information, see "Troubleshooting MS
	DTC Transactions" in SQL Server Books Online (BOL).

	When using modes of "block" or "block input", the result set contains all processes that are
	blocked or are causing the blocking. A blocking process (which may have exclusive locks) is
	one that is holding resources other SPIDs need to continue.

	The "Status" column gives a quick look at the status of a particular SPID. Typically,
	"sleeping" means the SPID has completed execution and is waiting for the application to submit
	another batch. The following list gives brief explanations for "Status" values:

	BACKGROUND	The SPID is performing a background task. This indicates a system thread.
	--
	DEFWAKEUP	Indicates that a SPID is waiting on a resource that is in the process of being
			freed. The "Wait" column should indicate the resource in question.
	--
	DORMANT 	Same as "sleeping", except a "DORMANT" SPID was reset after completing an RPC
			event from remote system (possibly a linked server). This cleans up resources
			and is normal; the SPID is available to execute. The system may	be caching the
			connection. Replication SPIDs show "DORMANT" when waiting.
	--
	ROLLBACK	The SPID is currently rolling back a transaction.
	--
	RUNNABLE 	The SPID is currently executing.
	--
	sleeping	The SPID is not currently executing. This usually indicates that the SPID is
			awaiting a command from the application.
	--
	SPINLOOP	The SPID is trying to acquire a spinlock used for SMP (multi-processor)
			concurrency control. It is using memory protected against multiple access. If a
			SPINLOOP process does not give up control, then it is likely SQL Server will
			become unresponsive and it is unlikely a KILL command will work on a process in
			this state. You may need to restart the server.
	--
	UNKNOWN TOKEN 	Indicates that the SPID is currently not executing a batch.
	----------------')

		PRINT ('
	The "Wait" column describes the resource type in question that the SPID is waiting for and how
	long it has waited. The following list gives brief explanations for "Wait" values:

	ASYNC_		During backup and restore threads are written in parallel. Indicates possible
	DISKPOOL_LOCK	disk bottleneck. See PhysicalDisk counters for confirmation.
	--
	ASYNC_I/O_	Waiting for asynchronous I/O requests to complete. Indicates possible disk
	COMPLETION	bottleneck, adding I/O bandwidth or balancing I/O across drives may help.
	--
	CMEMTHREAD	Waiting for thread-safe memory objects. Waiting on access to memory object.
	--
	CURSOR		Waiting for thread synchronization with asynchronous cursors.
	--
	CXPACKET	Waiting on packet synchronize up for exchange operator (parallel query).
	--
	DBTABLE		A new checkpoint request is waiting for a previous checkpoint to complete.
	--
	DTC		Waiting for Distributed Transaction Coordinator (DTC).
	--
	EC		Non-parallel synchronization between sub-thread or Execution Context.
	--
	EXCHANGE	Waiting on a parallel process to complete, shutdown, or startup.
	--
	EXECSYNC	Query memory and spooling to disk.
	--
	I/O_COMPLETION	Waiting for I/O requests to complete.
	--
	LATCH_x		Short-term light-weight synchronization objects. Latches are not held for the
			duration of a transaction. Latches are generally unrelated to I/O.
	--
	LATCH_DT	Destroy latch. See LATCH_x.
	--
	LATCH_EX	Exclusive latch. See LATCH_x.
	--
	LATCH_KP	Keep latch. See LATCH_x.
	--
	LATCH_NL	Null latch. See LATCH_x.
	--
	LATCH_SH	Shared latch. See LATCH_x.
	--
	LATCH_UP	Update latch. See LATCH_x.
	--
	LCK_M_BU	Bulk Update lock.
	--
	LCK_M_II_NL	Intent-Insert NULL (Key-Range) lock.
	--
	LCK_M_II_X	Intent-Insert Exclusive (Key-Range) lock.
	--
	LCK_M_IS	Intent-Shared lock.
	--
	LCK_M_IS_S	Intent-Shared Shared (Key-Range) lock.
	--
	LCK_M_IS_U	Intent-Shared Update (Key-Range) lock.
	--
	LCK_M_IU	Intent-Update lock.
	--
	LCK_M_IX	Intent-Exclusive lock.
	--
	LCK_M_RIn_NL	Range-Intent Null lock.
	--
	LCK_M_RIn_S	Range-Intent Shared lock.
	--
	LCK_M_RIn_U	Range-Intent Update lock.
	--
	LCK_M_RIn_X	Range-Intent Exclusive lock.
	--
	LCK_M_RS_S	Range-Shared Shared (Key-Range) lock.
	--
	LCK_M_RS_U	Range-Shared Update (Key-Range) lock.
	--
	LCK_M_RX_S	Range-Exclusive Shared (Key-Range) lock.
	--
	LCK_M_RX_U	Range-Exclusive Update (Key-Range) lock.
	--
	LCK_M_RX_X	Range-Exclusive Exclusive (Key-Range) lock.
	--
	LCK_M_S		Shared lock.
	--
	LCK_M_SCH_M	Schema Modification lock used for ALTER TABLE commands.
	--
	LCK_M_SCH_S	Schema Shared Stability lock.
	--
	LCK_M_SIU	Shared Intent to Update lock.
	--
	LCK_M_SIX	Shared Intent Exclusive lock.
	--
	LCK_M_U		Update lock used for the initial lock when doing updates.
	--
	LCK_M_UIX	Update Intent Exclusive lock.
	--
	LCK_M_X		Exclusive lock used for INSERT, UPDATE, and DELETE commands.
	--
	LOGMGR		Waiting for write requests for the transaction log to complete.
	--
	MISCELLANEOUS	Catch all wait types.
	--
	NETWORKIO	Waiting on network I/O. Waiting to read or write to a network client.
 	--
	OLEDB		Waiting on an OLE DB provider.
	--
	PAGEIOLATCH_x	Short-term synchronization objects used to synchronize access to buffer pages.
			PAGEIOLATCH_x is used for disk to memory transfers.
	--
	PAGEIOLATCH_DT	I/O page destroy latch.
	--
	PAGEIOLATCH_EX	I/O page latch exclusive. Waiting for the write of an I/O page.
	--
	PAGEIOLATCH_KP	I/O page latch keep.
	--
	PAGEIOLATCH_NL	I/O page latch null.
	--
	PAGEIOLATCH_SH	I/O page latch shared. Waiting for the read of an I/O page.
	--
	PAGEIOLATCH_UP	I/O page latch update.
	--
	PAGELATCH_x	Short-term light-weight synchronization objects. Page latching operations
			occur during row transfers to memory.
	--
	PAGELATCH_DT	Page latch destroy.
	--
	PAGELATCH_EX	Page latch exclusive.
	--
	PAGELATCH_KP	Page latch keep page.
	--
	PAGELATCH_NL	Page latch null.
	--
	PAGELATCH_SH	Page latch shared. Heavy concurrent inserts to the same index range can cause
			this type of contention. The solution in these cases is to distribute the
			inserts using a more appropriate index strategy.
	--
	PAGELATCH_UP	Page latch update. Contention for allocation of related pages. The contention
			indicates more data files are needed.
	--
	PAGESUPP	Release Spinlock in parallel query thread. Possible disk bottleneck.
	--
	PIPELINE_	Allows one user to perform multiple operations such as update index stats for
	INDEX_STAT	that user as well as other users waiting for the same operation.
	--
	PIPELINE_LOG	Allows one user to perform multiple operations such as writes to log for that
			user as well as other users waiting for the same operation.
	--
	PIPELINE_VLM	Allows one user to perform multiple operations.
	--
	PSS_CHILD	Waiting on a child thread in an asynchronous cursor operations.
	--
	RESOURCE_QUEUE	Internal use only.
 	--
	RESOURCE_	Waiting to a acquire a resource semaphore; must wait for memory grant. Used for
	SEMAPHORE	synchronization. Common for large queries such as hash joins.
	--
	SHUTDOWN	Wait for SPID to finish completion before shutdown completes.
	--
	SLEEP		Internal use only.
	--
	TEMPOBJ		Dropping a global temp object that is being used by others.
	--
	TRAN_MARK_DT	Transaction latch - destroy.
	--
	TRAN_MARK_EX	Transaction latch - exclusive.
	--
	TRAN_MARK_KP	Transaction latch - keep page.
	--
	TRAN_MARK_NL	Transaction latch - null.
	--
	TRAN_MARK_SH	Transaction latch - shared.
	--
	TRAN_MARK_UP	Transaction latch - update.
	--
	UMS_THREAD	Batch waiting for a worker thread to free up to run the batch.
	--
	WAITFOR		Wait initiated by a Transact-SQL WAITFOR statement.
	--
	WRITELOG	Waiting for write requests to the transaction log to complete.
	--
	XACTLOCKINFO	Waiting on bulk operation when releasing/escalating/transferring locks.
	--
	XCB		Acquiring access to a transaction control block (XCB). XCBs are usually private
			to a session, but can be shared between sessions when using bound sessions or
			multiple sessions in enlisting in the same DTC transaction.
	----------------')

		PRINT ('
Permissions:
	Execute permissions default to the public role. However, only members of the sysadmin or
	processadmin roles can execute "input", "active input", or "block input" run modes.

Examples:
	A. List all current processes.
		This example uses sp_who_3 without parameters to show all current processes.

		EXEC sp_who_3

		Here, all processes ordered by SPID then ECID ascending are returned.

	B. List current processes involved in blocking.
		This example uses "block" run mode to show blocked and blocking processes.

		EXEC sp_who_3
			@run_mode = ''block''

		Here, all blocked and blocking SPIDs are returned to help diagnose locking issues.

	C. List current active processes and order the results.
		This example uses "active" run mode and orders by "Login" and "SPID" descending.

		EXEC sp_who_3
			''active'',
			@o = ''2 DESC, 1 DESC''

		Here, active SPIDs sorted by Login Name and SPID descending are returned.

	D. List current processes with specific filters and order the results.
		This example uses filters on "SPID", "Program", and "Trans" while ordering by "DB".

		EXEC sp_who_3
			@spid = ''= 50'',
			@program = ''%sql%'',
			@trans = ''>= 1'',
			@o = ''DB ASC''

		Here, processes with a SPID of 50 (including all sub-thread ECIDs of SPID 50), which
		also contain "sql" anywhere in the Program Name, which have Transaction Counts greater
		than or equal to 1, and sorted by Database Name are returned.

	E. List current processes including input buffers with filters and order the results.
		This example uses "input" run mode to show process information while filtering on
		"SPID", "DB" and "Last_Batch". It also orders the results by "Status" ascending.

		EXEC sp_who_3
			@run_mode = ''input'',
			@spid = ''> 50'',
			@login = NULL,
			@host = NULL,
			@db = ''pubs'',
			@program = NULL,
			@status = NULL,
			@blk = NULL,
			@wait = NULL,
			@trans = NULL,
			@cpu = NULL,
			@dsk = NULL,
			@last_batch = ''>= 12/01/03 11:59:48'',
			@o = ''Status ASC''

		Here, the results contain processes meeting all filters ordered by the @o order by
		clause. Notice the use of comparison operators in the SPID and last_batch filters.')
	END

end_tran:
RETURN @error_code
GO
/*==============================================================
목적	: 로컬 트레이싱파일을 테이블로 전환
작성자	: 김준환
작성일	: 2004.08.06.
사용법	: EXEC dbo.up_ReadTrace N'TB_FMTrace', 'C:\TEMP\Trace\Trace.trc'
==============================================================*/
CREATE PROCEDURE [dbo].[up_ReadTrace](
					@p_TraceTableName	NVARCHAR(255),
					@p_TraceFile		NVARCHAR(255)
					)
AS

	DECLARE @v_SQL NVARCHAR(2000)
	
	SET @v_SQL = 
		'SELECT	Identity(int,1,1) as RowNum, * ' +
		'INTO	' + @p_TraceTableName + ' ' +
		'FROM	::fn_trace_gettable(''' + @p_TraceFile + ''', default)'
	PRINT @v_SQL
	
	EXEC dbo.sp_executesql @v_SQL
	
	SET @v_SQL = 
		'Create index ix_rownumber on ' + @p_TraceTableName + '(RowNum)'
	EXEC dbo.sp_executesql @v_SQL

	SET @v_SQL = 
		'create index ix_spid on ' + @p_TraceTableName + '(spid)'
	EXEC dbo.sp_executesql @v_SQL

	SET @v_SQL = 
		'create index ix_duration_cpu on ' + @p_TraceTableName + '(duration, cpu)'
	EXEC dbo.sp_executesql @v_SQL
	
	SET @v_SQL = 
		'create index ix_eventclass on ' + @p_TraceTableName + '(eventclass)'
	EXEC dbo.sp_executesql @v_SQL
	
RETURN
go

/*************************************************************************  
* 프로시저명  : dbo.up_dba_process_user_kill 
* 작성정보    : 2007-08-05
* 관련페이지  :  
* 내용        : 사용자 프로시저 Kill
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.sp_dba_process_user_kill
	@user_db_name		sysname,			    -- DataBase Name
	@logging_mode		smallint =1			-- 1:NO LOGGING, 2: LOGGING(LOGGING TABLE : KILLED_PROCESS_HISTORY)
AS
	/* COMMON DECLARE */
	set nocount on
	set transaction isolation level read uncommitted

	/* USER DECLARE */
	declare @iSessionListCnt	smallint	-- KILL 해야되는 process개수
	declare @iLoopCnt			int			-- Loop Counter
	declare @sSql				nvarchar(100)		-- KILL SQL 
	declare @iSessionId			int			-- session id

	create table #tblSessionList
	    (
		seq_no				int		not null identity(1,1)
	,	session_id			smallint		not null	-- session id
	)
    
	-- index 생성
	create index idx__seq_no on #tblSessionList (seq_no)
	create clustered index cidx__session_id on #tblSessionList (session_id)
    
	/* BODY */
	insert into #tblSessionList(session_id)
	SELECT distinct(spid)
	FROM master.dbo.sysprocesses WITH (NOLOCK)   
	  WHERE dbid = db_id(@user_db_name) AND spid > 50  
	
	/*select req.session_id
	from sys.dm_exec_requests as req with (nolock)
	inner join master..sysdatabases as cat with (nolock) on req.database_id = cat.dbid
	where req.session_id > 50
	  and UPPER(cat.name) = @user_db_name */
    
	set @iSessionListCnt = @@ROWCOUNT
    
	if @iSessionListCnt = 0
	begin
		return;
	end

	-- PROCESS KILL
	if (@logging_mode = 2)
	begin
		
		insert into dba.dbo.KILLED_PROCESS_HISTORY
		(
						session_id
		,               user_db_name
		,				start_time
		,				status
		,				command
		,				sql_text
		)
		select 
			req.session_id,
			DB_NAME(req.database_id) as user_db_name,
			req.start_time, 
			req.status, 
			req.command, 
			(select text from sys.dm_exec_sql_text(req.sql_handle)) as sql
		   from sys.dm_exec_requests as req with (nolock)
		   inner join #tblSessionList as ses with (nolock) on req.session_id = ses.session_id

	end

	--loop counter 초기화
	set @iLoopCnt = 1

	while (@iLoopCnt <= @iSessionListCnt)
	begin
		select @iSessionId = session_id from dbo.#tblSessionList with (nolock) where seq_no = @iLoopCnt

		SET @sSql = ' KILL ' + cast(@iSessionId as varchar)

		EXEC sp_executesql @sSql

		set @iLoopCnt = @iLoopCnt + 1

		if (@iLoopCnt > @iSessionListCnt)
		begin
			return;
		end
	end 
		
	drop table #tblSessionList

	set nocount off
go

USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO
