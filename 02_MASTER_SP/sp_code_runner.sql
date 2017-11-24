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