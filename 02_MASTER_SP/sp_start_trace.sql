USE master
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
@IncludeTextFilter sysname=NULL,@ExcludeTextFilter sysname=NULL,
@IncludeObjIdFilter int=NULL,
@IncludeHostFilter int=NULL,
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
--hostName
IF @IncludeHostFilter IS NOT NULL EXEC sp_trace_setfilter @traceid=@QueueHandle, @columnid=8, @logical_operator=0, @comparison_operator=0, @value=@IncludeHostFilter

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

-- 실행하는 법.
--exec sp_start_trace '/?'
--exec sp_start_trace 'c:\temp\trace10.trc'
