use master
go




CREATE PROCEDURE [dbo].[sp_CapacityPlanning] AS

/*
----------------------------------------------------------------------------
-- Object Name: sp_CapacityPlanning
-- Project: Capacity Planning
-- Business Process: Capacity Planning
-- Purpose: Calculate the capacity planning for 1, 2 and 3 years for the database and transaction log
-- Detailed Description: Capture static information and write infromation to the 
-- dbo.CapacityPlanning table for the database and transaction log calculations
-- Database: TBD
-- Dependent Objects: 
-- - Master.dbo.sysdatabases
- MSDB.dbo.backupset
- TBD.dbo.CapacityPlanning 
-- Called By: TBD
-- Upstream Systems: N\A
-- Downstream Systems: N\A

-- 
--------------------------------------------------------------------------------------
-- Rev | CMR | Date Modified | Developer | Change Summary
--------------------------------------------------------------------------------------
-- 001 | N\A | 06.15.2007 | Edgewood | Original code
--
*/

SET NOCOUNT ON

-- Step 1 - Preliminary Information
SELECT @@SERVERNAME AS 'Server Name'
SELECT GETDATE() AS 'Execution Timestamp'
PRINT '--------------------------------------------------------'
PRINT '********************************************************'
PRINT ''
SELECT 'Disk Space Availablity'
PRINT ''
PRINT '********************************************************'
PRINT '--------------------------------------------------------'
PRINT ''
PRINT ''
EXEC Master.dbo.xp_fixeddrives



DECLARE @CapacityPlanning TABLE (
[CPID] [int] IDENTITY (1, 1) NOT NULL ,
[ServerName] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
[DatabaseName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
[ExecutionDateTime] [datetime] NULL ,
[NewDatabaseSize] [decimal](18, 0) NULL ,
[OldDatabaseSize] [decimal](18, 0) NULL ,
[NewCreationDate] [datetime] NULL ,
[OldCreationDate] [datetime] NULL ,
[VarDiff] [decimal](18, 0) NULL ,
[PercentGrowth] [decimal](18, 0) NULL ,
[AvgGrowth] [decimal](18, 0) NULL ,
[DateDiff] [decimal](18, 0) NULL ,
[Yr1DBProjections] [decimal](18, 0) NULL ,
[Yr1LogProjections] [decimal](18, 0) NULL ,
[Yr1DBProjections15Percent] [decimal](18, 0) NULL ,
[Yr1LogProjections15Percent] [decimal](18, 0) NULL ,
[Total1YrProj] [decimal](18, 0) NULL ,
[Total1YrProj15Percent] [decimal](18, 0) NULL ,
[Yr2DBProjections] [decimal](18, 0) NULL ,
[Yr2LogProjections] [decimal](18, 0) NULL ,
[Yr2DBProjections15Percent] [decimal](18, 0) NULL ,
[Yr2LogProjections15Percent] [decimal](18, 0) NULL ,
[Total2YrProj] [decimal](18, 0) NULL ,
[Total2YrProj15Percent] [decimal](18, 0) NULL ,
[Yr3DBProjections] [decimal](18, 0) NULL ,
[Yr3LogProjections] [decimal](18, 0) NULL ,
[Yr3DBProjections15Percent] [decimal](18, 0) NULL ,
[Yr3LogProjections15Percent] [decimal](18, 0) NULL ,
[Total3YrProj] [decimal](18, 0) NULL ,
[Total3YrProj15Percent] [decimal](18, 0) NULL ,
[TotalNumberofDatabases] [int] NULL 
) 

-- Step 2 - Declare the cursor variables
--Prepatory Variables
DECLARE @DatabaseName VARCHAR(50)
DECLARE @ExecutionDateTime DateTime
DECLARE @NewDatabaseSize Decimal
DECLARE @OldDatabaseSize Decimal
DECLARE @NewCreationDate DateTime
DECLARE @OldCreationDate DateTime
DECLARE @VarDiff Decimal
DECLARE @PercentGrowth Decimal
DECLARE @AvgGrowth Decimal
DECLARE @DateDiff Decimal

-- 1 Year Variables
DECLARE @Yr1DBProjections Decimal
DECLARE @Yr1LogProjections Decimal
DECLARE @Yr1DBProjections15Percent Decimal
DECLARE @Yr1LogProjections15Percent Decimal

-- 2 Year Variables
DECLARE @Yr2DBProjections Decimal
DECLARE @Yr2LogProjections Decimal
DECLARE @Yr2DBProjections15Percent Decimal
DECLARE @Yr2LogProjections15Percent Decimal

-- 3 Year Variables
DECLARE @Yr3DBProjections Decimal
DECLARE @Yr3LogProjections Decimal
DECLARE @Yr3DBProjections15Percent Decimal
DECLARE @Yr3LogProjections15Percent Decimal

-- Total Historical Variables
DECLARE @TotalRecentDatabaseSize Decimal
DECLARE @TotalOldDatabaseSize Decimal
DECLARE @TotalDiffDatabaseSize Decimal
DECLARE @TotalPercentageGrowth Decimal
DECLARE @AvgPercentageGrowth Decimal
DECLARE @AvgDateDiff Decimal
DECLARE @TotalNumberofDatabases Decimal
DECLARE @TotalDateDiff Decimal 

-- Total Projection Variables
DECLARE @Total1YrDBProj Decimal
DECLARE @Total1YrLogProj Decimal
DECLARE @Total1YrDBProj15Percent Decimal
DECLARE @Total1YrLogProj15Percent Decimal
DECLARE @Total1YrProj Decimal -- Database and Log
DECLARE @Total1YrProj15Percent Decimal -- Database and Log

DECLARE @Total2YrDBProj Decimal
DECLARE @Total2YrLogProj Decimal
DECLARE @Total2YrDBProj15Percent Decimal
DECLARE @Total2YrLogProj15Percent Decimal
DECLARE @Total2YrProj Decimal -- Database and Log
DECLARE @Total2YrProj15Percent Decimal -- Database and Log

DECLARE @Total3YrDBProj Decimal
DECLARE @Total3YrLogProj Decimal
DECLARE @Total3YrDBProj15Percent Decimal
DECLARE @Total3YrLogProj15Percent Decimal
DECLARE @Total3YrProj Decimal -- Database and Log
DECLARE @Total3YrProj15Percent Decimal -- Database and Log

DECLARE @nDBCnt   smallint
DECLARE @nLoopCnt smallint
DECLARE @db_name  sysname
DECLARE @CapPlanDBName TABLE
(
    seq_no      smallint identity(1,1)
,   db_name     sysname
)


-- Initialize Historical Variables 
SELECT @ExecutionDateTime = GETDATE()
SELECT @TotalNumberofDatabases = 0
SELECT @TotalRecentDatabaseSize = 0
SELECT @TotalOldDatabaseSize = 0
SELECT @TotalDiffDatabaseSize = 0
SELECT @TotalPercentageGrowth = 0
SELECT @AvgPercentageGrowth = 0
SELECT @AvgDateDiff = 0
SELECT @TotalDateDiff = 0
SELECT @nLoopCnt = 1

SELECT @Total1YrDBProj = 0
SELECT @Total1YrLogProj = 0
SELECT @Total1YrDBProj15Percent = 0
SELECT @Total1YrLogProj15Percent = 0
SELECT @Total1YrProj = 0 -- Database and Log
SELECT @Total1YrProj15Percent = 0-- Database and Log

SELECT @Total2YrDBProj = 0
SELECT @Total2YrLogProj = 0
SELECT @Total2YrDBProj15Percent = 0
SELECT @Total2YrLogProj15Percent = 0
SELECT @Total2YrProj = 0 -- Database and Log
SELECT @Total2YrProj15Percent = 0 -- Database and Log

SELECT @Total3YrDBProj = 0
SELECT @Total3YrLogProj = 0
SELECT @Total3YrDBProj15Percent = 0
SELECT @Total3YrLogProj15Percent = 0
SELECT @Total3YrProj = 0 -- Database and Log
SELECT @Total3YrProj15Percent = 0 -- Database and Log

-- Step 3 - Begin Cursor Processing
INSERT INTO @CapPlanDBName(db_name)
SELECT Name
  FROM sys.databases WITH (NOLOCK)
 WHERE database_id > 4
ORDER BY Name

SET @nDBCnt = @@ROWCOUNT

WHILE (@nDBCnt >= @nLoopCnt)
BEGIN
    -- Prepatory Calculations
    SELECT @db_name = db_name
      FROM @CapPlanDBName
     WHERE seq_no = @nLoopCnt

    SELECT @NewDatabaseSize = ((backup_size)/1024/1024), @NewCreationDate = (backup_start_date) 
    FROM MSDB.dbo.backupset WITH (NOLOCK)
    WHERE database_name = @db_name
    AND TYPE = 'D'
    ORDER BY backup_set_id 

    SELECT @OldDatabaseSize = ((backup_size)/1024/1024), @OldCreationDate = (backup_start_date)
    FROM MSDB.dbo.backupset WITH (NOLOCK)
    WHERE database_name = @db_name
    AND TYPE = 'D'
    ORDER BY backup_set_id DESC

    SELECT @VarDiff = (@NewDatabaseSize - @OldDatabaseSize)
    SELECT @PercentGrowth = (((@NewDatabaseSize/@OldDatabaseSize)-1)* 100)
    SELECT @DateDiff = DATEDIFF(dd, @OldCreationDate, @NewCreationDate) 
    IF @DateDiff = 0
    BEGIN
        SET @DateDiff = 1
    END
    SELECT @AvgGrowth = (@VarDiff/@DateDiff)

    -- Year 1 Figures 
    SELECT @Yr1DBProjections = ((@AvgGrowth * 365) + @NewDatabaseSize)
    SELECT @Yr1DBProjections15Percent = ((@Yr1DBProjections * .15) + @Yr1DBProjections)
    SELECT @Yr1LogProjections = (@Yr1DBProjections/4)
    SELECT @Yr1LogProjections15Percent = ((@Yr1LogProjections * .15) + @Yr1LogProjections)

    -- Year 2 Figures
    SELECT @Yr2DBProjections = ((@AvgGrowth * 730) + @NewDatabaseSize)
    SELECT @Yr2DBProjections15Percent = ((@Yr2DBProjections * .15) + @Yr2DBProjections)
    SELECT @Yr2LogProjections = (@Yr2DBProjections/4)
    SELECT @Yr2LogProjections15Percent = ((@Yr2LogProjections * .15) + @Yr2LogProjections)

    -- Year 3 Figures
    SELECT @Yr3DBProjections = ((@AvgGrowth * 1095) + @NewDatabaseSize)
    SELECT @Yr3DBProjections15Percent = ((@Yr3DBProjections * .15) + @Yr3DBProjections)
    SELECT @Yr3LogProjections = (@Yr3DBProjections/4)
    SELECT @Yr3LogProjections15Percent = ((@Yr3LogProjections * .15) + @Yr3LogProjections)

    -- Calculation Totals 
    SELECT @TotalRecentDatabaseSize = @TotalRecentDatabaseSize + @NewDatabaseSize
    SELECT @TotalOldDatabaseSize = @TotalOldDatabaseSize + @OldDatabaseSize
    SELECT @TotalDiffDatabaseSize = @TotalDiffDatabaseSize + @VarDiff
    SELECT @TotalNumberofDatabases = @TotalNumberofDatabases + 1
    SELECT @TotalPercentageGrowth = @TotalPercentageGrowth + @AvgGrowth 
    SELECT @TotalDateDiff = @TotalDateDiff + @DateDiff 

    -- Year 1 Projection Totals
    SELECT @Total1YrDBProj = @Yr1DBProjections + @Total1YrDBProj
    SELECT @Total1YrLogProj = @Yr1LogProjections + @Total1YrLogProj
    SELECT @Total1YrDBProj15Percent = @Yr1DBProjections15Percent + @Total1YrDBProj15Percent
    SELECT @Total1YrLogProj15Percent = @Yr1LogProjections15Percent + @Total1YrLogProj15Percent

    -- Year 2 Projection Totals
    SELECT @Total2YrDBProj = @Yr2DBProjections + @Total2YrDBProj
    SELECT @Total2YrLogProj = @Yr2LogProjections + @Total2YrLogProj
    SELECT @Total2YrDBProj15Percent = @Yr2DBProjections15Percent + @Total2YrDBProj15Percent
    SELECT @Total2YrLogProj15Percent = @Yr2LogProjections15Percent + @Total2YrLogProj15Percent

    -- Year 3 Projection Totals
    SELECT @Total3YrDBProj = @Yr3DBProjections + @Total3YrDBProj
    SELECT @Total3YrLogProj = @Yr3LogProjections + @Total3YrLogProj
    SELECT @Total3YrDBProj15Percent = @Yr3DBProjections15Percent + @Total3YrDBProj15Percent
    SELECT @Total3YrLogProj15Percent = @Yr3LogProjections15Percent + @Total3YrLogProj15Percent

    -- Insert values into the dbo.CapacityPlanning table
    INSERT INTO @CapacityPlanning
    ( 
    ServerName 
    ,DatabaseName 
    ,ExecutionDateTime 
    ,NewDatabaseSize 
    ,OldDatabaseSize 
    ,NewCreationDate 
    ,OldCreationDate 
    ,VarDiff 
    ,PercentGrowth 
    ,AvgGrowth 
    ,DateDiff 
    ,Yr1DBProjections 
    ,Yr1LogProjections 
    ,Yr1DBProjections15Percent 
    ,Yr1LogProjections15Percent 
    ,Yr2DBProjections 
    ,Yr2LogProjections 
    ,Yr2DBProjections15Percent 
    ,Yr2LogProjections15Percent 
    ,Yr3DBProjections 
    ,Yr3LogProjections 
    ,Yr3DBProjections15Percent 
    ,Yr3LogProjections15Percent 
    )
    VALUES
    (
    @@ServerName 
    ,@db_name 
    ,@ExecutionDateTime 
    ,@NewDatabaseSize 
    ,@OldDatabaseSize 
    ,@NewCreationDate 
    ,@OldCreationDate 
    ,@VarDiff 
    ,@PercentGrowth 
    ,@AvgGrowth 
    ,@DateDiff 
    ,@Yr1DBProjections 
    ,@Yr1LogProjections 
    ,@Yr1DBProjections15Percent 
    ,@Yr1LogProjections15Percent 
    ,@Yr2DBProjections 
    ,@Yr2LogProjections 
    ,@Yr2DBProjections15Percent 
    ,@Yr2LogProjections15Percent 
    ,@Yr3DBProjections 
    ,@Yr3LogProjections 
    ,@Yr3DBProjections15Percent 
    ,@Yr3LogProjections15Percent 
    )

    SET @nLoopCnt = @nLoopCnt + 1
END

-- Step 4 - Calculate Aggregates
-- Historical Totals
SELECT @AvgPercentageGrowth = (@TotalPercentageGrowth/@TotalNumberofDatabases)
SELECT @AvgDateDiff = (@TotalDateDiff/@TotalNumberofDatabases) 

-- Year 1 Totals
SELECT @Total1YrProj = @Total1YrDBProj + @Total1YrLogProj -- Database and Log
SELECT @Total1YrProj15Percent = @Total1YrDBProj15Percent + @Total1YrLogProj15Percent -- Database and Log

-- Year 2 Totals
SELECT @Total2YrProj = @Total2YrDBProj + @Total2YrLogProj -- Database and Log
SELECT @Total2YrProj15Percent = @Total2YrDBProj15Percent + @Total2YrLogProj15Percent -- Database and Log

-- Year 3 Totals
SELECT @Total3YrProj = @Total3YrDBProj + @Total3YrLogProj -- Database and Log
SELECT @Total3YrProj15Percent = @Total3YrDBProj15Percent + @Total3YrLogProj15Percent -- Database and Log

-- Step 5 - Insert Into Capacity Planning Table
INSERT INTO @CapacityPlanning
(ServerName
,DatabaseName
,ExecutionDateTime
,NewDatabaseSize
,OldDatabaseSize
,NewCreationDate
,OldCreationDate
,VarDiff
,PercentGrowth
,AvgGrowth
,DateDiff
,Yr1DBProjections
,Yr1LogProjections
,Yr1DBProjections15Percent
,Yr1LogProjections15Percent
,Total1YrProj
,Total1YrProj15Percent
,Yr2DBProjections
,Yr2LogProjections
,Yr2DBProjections15Percent
,Yr2LogProjections15Percent
,Total2YrProj
,Total2YrProj15Percent
,Yr3DBProjections
,Yr3LogProjections
,Yr3DBProjections15Percent
,Yr3LogProjections15Percent
,Total3YrProj
,Total3YrProj15Percent
,TotalNumberofDatabases
)
VALUES
(
@@ServerName 
,'Total Calculations' 
,@ExecutionDateTime 
,@TotalRecentDatabaseSize 
,@TotalOldDatabaseSize 
,NULL
,NULL
,@TotalDiffDatabaseSize 
,NULL -- @AvgPercentageGrowth 
,@TotalPercentageGrowth 
,@AvgDateDiff 
,@Total1YrDBProj 
,@Total1YrLogProj
,@Total1YrDBProj15Percent 
,@Total1YrLogProj15Percent 
,@Total1YrProj
,@Total1YrProj15Percent 
,@Total2YrDBProj
,@Total2YrLogProj
,@Total2YrDBProj15Percent 
,@Total2YrLogProj15Percent 
,@Total2YrProj
,@Total2YrProj15Percent 
,@Total3YrDBProj
,@Total3YrLogProj
,@Total3YrDBProj15Percent 
,@Total3YrLogProj15Percent 
,@Total3YrProj
,@Total3YrProj15Percent
,@TotalNumberofDatabases 
)

-- Step 6 - Generate Report 
SELECT *
FROM @CapacityPlanning
WHERE ExecutionDateTime = @ExecutionDateTime 

SET NOCOUNT OFF
go




CREATE PROC [dbo].[sp_code_runner] 
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
go

--sp_dba_help_file_size 'LION'
/*************************************************************************  
* 프로시저명  : dbo.sp_dba_help_file_size
* 작성정보    : 2013-04-18 서은미
* 관련페이지  :  
* 내용        :DB 파일 사이즈 계산
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_dba_help_file_size]
     @db_name SYSNAME
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @sql VARCHAR(2000)
/* BODY */

IF @db_name IS NULL OR @db_name = ''
BEGIN
	RAISERROR (N'input param error', 16,1)	
	RETURN
END

SET @sql = 
'
USE '+@db_name+';
SELECT
	a.name AS LogicalFileName,
	CAST(a.size/128.0 AS int) AS FileSize,
	g.groupname, 
	a.name AS LogicalFileName, a.filename AS PhysicalFileName, 
	CAST(a.size/128.0 - CAST(FILEPROPERTY(a.name, ''SpaceUsed'' ) AS int)/128.0 AS int) AS FreeSpaceMB, 
	CAST(100 * (CAST (((a.size/128.0 -CAST(FILEPROPERTY(a.name, ''SpaceUsed'' ) AS int)/128.0)/(a.size/128.0)) AS decimal(4,2))) AS varchar(8)) + ''%'' AS FreeSpacePct, 
	a.growth, a.maxsize,
	GETDATE() as PollDate 
FROM '+@db_name+'.dbo.sysfiles a with(nolock) left join  '+@db_name+'.sys.sysfilegroups as g with(nolock) 
on a.groupid = g.groupid
ORDER BY g.groupname, a.name
'   
--PRINT @sql
EXEC (@sql)
go

CREATE PROC [dbo].[SP_DBA_SERVICE_CHANGE_SCRIPT]
@old_sql_login VARCHAR(20),  
@new_sql_login VARCHAR(20),  
@database_name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL VARCHAR(4000), @SEQNO INT, @MAX_SEQNO INT, @CLASS VARCHAR(20), @NAME VARCHAR(200), @SCHEMA_NAME VARCHAR(100)  
	
	CREATE TABLE #temp  
	(  
	SEQNO INT IDENTITY(1,1),  
	class_desc varchar(20),  
	schema_name varchar(100),
	object_name varchar(200),  
	name varchar(200),  
	state_desc varchar(100)  
	) 

	CREATE TABLE #temp1  
	(  
	SEQNO INT IDENTITY(1,1),  
	class_desc varchar(20),  
	schema_name varchar(100),
	object_name varchar(200),  
	name varchar(200),  
	state_desc varchar(100)  
	) 

	CREATE TABLE #temp2
	(  
	SEQNO INT IDENTITY(1,1),  
	class_desc varchar(20),  
	schema_name varchar(100),
	object_name varchar(200),  
	name varchar(200),  
	state_desc varchar(100)  
	) 
 
	BEGIN
	SET @SQL = 
	'INSERT INTO #temp1  
	SELECT    
	*  
	FROM (  
	SELECT   
	dpm.class_desc
	, sc.name as schema_name
	, case when dpm.major_id = 0 then ''ALL'' else obj.name end as object_name  
	, dpm.permission_name collate korean_wansung_ci_as as name   
	, dpm.state_desc  as state_desc  
	from '+@database_name+'.sys.database_principals as dpr with (nolock)  
	inner join '+@database_name+'.sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id  
	left outer join '+@database_name+'.sys.all_objects as obj with (nolock) on dpm.major_id = obj.object_id
	JOIN '+@database_name+'.sys.schemas AS sc WITH (NOLOCK) ON obj.schema_id = sc.schema_id
	where dpr.name = ''' + @old_sql_login + '''  
	UNION ALL  
	SELECT   
	''ROLE'' as class_desc  
	, ''''  as schema_name
	, ''ALL''  as object_name
	, su1.name collate korean_wansung_ci_as as name   
	, ''GRANT'' as state_desc  
	FROM '+@database_name+'.sys.sysmembers sm											
	JOIN '+@database_name+'.sys.sysusers su1 ON  sm.groupuid = su1.uid  
	JOIN '+@database_name+'.sys.sysusers su2 ON  sm.memberuid = su2.uid			
	WHERE su2.name =  ''' + @old_sql_login + '''  
	) A
	
	INSERT INTO #temp2  
	SELECT    
	*  
	FROM (  
	SELECT   
	dpm.class_desc
	, sc.name as schema_name
	, case when dpm.major_id = 0 then ''ALL'' else obj.name end as object_name  
	, dpm.permission_name collate korean_wansung_ci_as as name   
	, dpm.state_desc  as state_desc  
	from '+@database_name+'.sys.database_principals as dpr with (nolock)  
	inner join '+@database_name+'.sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id  
	left outer join '+@database_name+'.sys.all_objects as obj with (nolock) on dpm.major_id = obj.object_id
	JOIN '+@database_name+'.sys.schemas AS sc WITH (NOLOCK) ON obj.schema_id = sc.schema_id
	where dpr.name = ''' + @new_sql_login + '''  
	UNION ALL  
	SELECT   
	''ROLE'' as class_desc  
	, ''''  as schema_name
	, ''ALL''  as object_name
	, su1.name collate korean_wansung_ci_as as name   
	, ''GRANT'' as state_desc  
	FROM '+@database_name+'.sys.sysmembers sm											
	JOIN '+@database_name+'.sys.sysusers su1 ON  sm.groupuid = su1.uid  
	JOIN '+@database_name+'.sys.sysusers su2 ON  sm.memberuid = su2.uid			
	WHERE su2.name =  ''' + @new_sql_login + '''  
	) A

	INSERT INTO #temp
	SELECT A.class_desc, A.schema_name, A.object_name, A.name, A.state_desc
	FROM #temp1 A (NOLOCK)
	LEFT JOIN #temp2 B (NOLOCK) ON ISNULL(A.name, ''1'') = ISNULL(B.name, ''1'') AND ISNULL(A.schema_name, ''1'') = ISNULL(B.schema_name, ''1'') 
	AND ISNULL(A.object_name, ''1'') = ISNULL(B.object_name, ''1'') AND ISNULL(A.state_desc, ''1'') = ISNULL(B.state_desc, ''1'')
	WHERE B.object_name IS NULL
	'
 
	EXEC (@SQL)
	--PRINT (@SQL)

	DECLARE @T_CNT INT, @O_CNT INT, @N_CNT INT
	SELECT @N_CNT = COUNT(*) FROM #temp
	WHERE NAME NOT IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT')
	SELECT @T_CNT = COUNT(*) FROM #temp1
	WHERE NAME NOT IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT')
	SELECT @O_CNT = COUNT(*) FROM #temp2
	WHERE NAME NOT IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT')

	SELECT @database_name AS DB_NAME, @T_CNT AS '기존계정권한수', @O_CNT AS '이미부여된권한수', @N_CNT AS '새로부여할권한수'
	--SELECT * FROM #temp (NOLOCK)
	--WHERE NAME NOT IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT')
	--SELECT * FROM #temp1 (NOLOCK)
	--SELECT * FROM #temp2 (NOLOCK)

	PRINT ''
	END   

	IF @N_CNT > 0  
	BEGIN  
	SET @SEQNO = 1  
	SELECT @MAX_SEQNO = MAX(SEQNO) FROM #temp  
	PRINT 'USE [' + @database_name  + ']'

	WHILE (1=1)  
	BEGIN  
		IF @SEQNO = 1
		BEGIN
			SET @SQL = ''
        
			SET @SQL = @SQL + 'IF NOT EXISTS (SELECT 1 FROM SYSUSERS WHERE NAME = ''' + @new_sql_login + ''')' + CHAR(10) + 'BEGIN' + CHAR(10)
			SET @SQL = @SQL + 'CREATE USER [' + @new_sql_login + '] FOR LOGIN [' + @new_sql_login  + ']' + CHAR(10) + 'END' + CHAR(10) + 'GO'

			PRINT @SQL
		END

		SET @SQL = ''

		SELECT @CLASS = class_desc, @NAME = NAME, @SCHEMA_NAME = ISNULL(SCHEMA_NAME, '')
		FROM #temp  
		WHERE SEQNO = @SEQNO
	
		--SELECT @CLASS = A.class_desc, @NAME = A.NAME, @SCHEMA_NAME = A.SCHEMA_NAME
		--FROM #temp A (NOLOCK)
		--LEFT JOIN #temp2 B (NOLOCK) ON A.name = B.name AND A.schema_name = B.schema_name AND A.object_name = B.object_name AND A.state_desc = B.state_desc
		--WHERE B.object_name IS NULL
		--AND SEQNO = @SEQNO  
		--PRINT @CLASS
		IF @CLASS = 'DATABASE'  
		BEGIN  
			--계정 생성
			IF @NAME != 'CONNECT'
			BEGIN  
				SELECT @SQL = state_desc + ' ' + schema_name + '.'+ name + ' TO ' + @new_sql_login + CHAR(10) + 'GO'
				FROM #temp  
				WHERE SEQNO = @SEQNO  
			END
		END  
     
		IF @SQL <> ''  
		BEGIN  
			PRINT @SQL  
		END  
     
		IF @SEQNO = @MAX_SEQNO  
		BEGIN  
			BREAK  
		END  
     
		SET @SEQNO = @SEQNO + 1  
		END  
  
		SET @SEQNO = 1  
  
		WHILE (1=1)  
		BEGIN  
			SET @SQL = ''  
     
			SELECT @CLASS = class_desc  
			FROM #temp  
			WHERE SEQNO = @SEQNO    
			--역할 생성
			IF @CLASS = 'ROLE'  
			BEGIN     
				SELECT @SQL = 'EXEC sp_addrolemember ''' + name + ''',''' + @new_sql_login + ''''   + CHAR(10) + 'GO'
				FROM #temp  
				WHERE SEQNO = @SEQNO  
			END  
         
			IF @SQL <> ''  
			BEGIN  
				PRINT @SQL  
			END  
     
			IF @SEQNO = @MAX_SEQNO  
			BEGIN  
				BREAK  
			END  
     
			SET @SEQNO = @SEQNO + 1
		END   
  
		SET @SEQNO = 1  
  
		WHILE (1=1)  
		BEGIN  
			SET @SQL = ''  
     
			SELECT @CLASS = class_desc  
			FROM #temp  
			WHERE SEQNO = @SEQNO   
			--객체 권한 생성
			IF @CLASS = 'OBJECT_OR_COLUMN'  
			BEGIN     
				SELECT @SQL = state_desc + ' ' + name + ' ON [' + SCHEMA_NAME + '].[' + object_name + '] TO ' + @new_sql_login   + CHAR(10) + 'GO'
				FROM #temp  
				WHERE SEQNO = @SEQNO
				AND name NOT IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT')
			END  
          
			IF @SQL <> ''  
			BEGIN  
				PRINT @SQL  
			END    
	 
			IF @SEQNO = @MAX_SEQNO  
			BEGIN  
				BREAK  
			END  
     
			SET @SEQNO = @SEQNO + 1    
		END    
	END
END
go

CREATE PROC [dbo].[SP_DBA_SERVICE_GRANT_SCRIPT]
	@old_sql_login VARCHAR(20)  
,	@new_sql_login VARCHAR(20)  
,	@database_name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL VARCHAR(MAX), @PRINT VARCHAR(MAX)
	DECLARE @MIN_SEQNO BIGINT, @MAX_SEQNO BIGINT

	CREATE TABLE #temp  
	(  
	SEQNO INT IDENTITY(1,1),  
	SCHEMA_NAME VARCHAR(100),
	SP_NAME VARCHAR(MAX)
	) 

	SET @SQL = 'INSERT INTO #temp (SCHEMA_NAME, SP_NAME)
SELECT sc.name AS SCHEMA_NAME, SP.name AS SP_NAME
FROM ' + @database_name + '.sys.all_objects SP (NOLOCK) 
JOIN '+@database_name+'.sys.schemas AS sc WITH (NOLOCK) ON SP.schema_id = sc.schema_id
WHERE sc.name = ''' + @old_sql_login + ''' AND SP.TYPE IN (''P'', ''FN'')'

	EXEC (@SQL)
	--PRINT @SQL

	SET @MIN_SEQNO = 1
	SELECT @MAX_SEQNO = MAX(SEQNO) FROM #temp (NOLOCK)

	WHILE (@MIN_SEQNO <= @MAX_SEQNO)
	BEGIN
		IF @MIN_SEQNO = 1
		BEGIN
			PRINT 'USE ' + @database_name + CHAR(10) + 'GO'
		END
		SELECT @PRINT = 'GRANT EXEC ON [' + SCHEMA_NAME + '].[' + SP_NAME + '] TO ' + @new_sql_login + CHAR(10) + 'GO'
		FROM #temp (NOLOCK)
		WHERE SEQNO = @MIN_SEQNO

		SET @MIN_SEQNO = @MIN_SEQNO + 1

		PRINT @PRINT
	END

END


go

CREATE PROCEDURE [dbo].[sp_diskspace]
AS      
/*      
   Displays the free space,free space percentage       
   plus total drive size for a server      
*/      
SET NOCOUNT ON      
      
DECLARE @hr int      
DECLARE @fso int      
DECLARE @drive char(1)      
DECLARE @odrive int      
DECLARE @TotalSize varchar(20)      
DECLARE @MB bigint ; SET @MB = 1048576      
    
TRUNCATE TABLE DBA..DISK_USAGE    
    
CREATE TABLE #drives (drive char(1) PRIMARY KEY,      
                      FreeSpace int NULL,      
                      TotalSize int NULL)      
      
INSERT #drives(drive,FreeSpace)       
EXEC master.dbo.xp_fixeddrives      
      
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT      
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso      
      
DECLARE dcur CURSOR LOCAL FAST_FORWARD      
FOR SELECT drive from #drives      
ORDER by drive      
      
OPEN dcur      
      
FETCH NEXT FROM dcur INTO @drive      
      
WHILE @@FETCH_STATUS=0      
BEGIN      
      
        EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive      
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso      
              
        EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT      
        IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive      
                              
        UPDATE #drives      
        SET TotalSize=@TotalSize/@MB      
        WHERE drive=@drive      
              
        FETCH NEXT FROM dcur INTO @drive      
      
END      
      
CLOSE dcur      
DEALLOCATE dcur      
      
EXEC @hr=sp_OADestroy @fso      
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso      
    
INSERT INTO DBA..DISK_USAGE      
SELECT drive,      
       FreeSpace as 'Free(MB)',      
       TotalSize as 'Total(MB)',      
       CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Free(%)'      
FROM #drives      
ORDER BY drive      
    
SELECT drive,      
       FreeSpace as 'Free(MB)',      
       TotalSize as 'Total(MB)',      
       CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Free(%)'      
FROM #drives      
ORDER BY drive      
      
DROP TABLE #drives      
      
RETURN




go

/*************************************************************************  
* 프로시저명  : dbo.SP_HELP_COLUMN
* 작성정보    : 2013-08-01 Noh, sangkook
* 관련페이지  : 
* 내용        : 테이블 확장속성 확인
* 수정정보    :
use item
go
SP_HELP_COLUMN  'GOODS'
**************************************************************************/
CREATE PROC [dbo].[SP_HELP_COLUMN]
@TABLE_NAME SYSNAME
AS

SET NOCOUNT ON
DECLARE @STR_SQL  NVARCHAR(4000), @STR_PARM NVARCHAR(500)
DECLARE @DB_NAME SYSNAME

SELECT @DB_NAME = DB_NAME()


SET @STR_SQL= 'SELECT OBJECT_NAME(MAJOR_ID) AS [TABLE NAME], VALUE ' +CHAR(10)
							+ 'FROM ' + @DB_NAME + '.SYS.EXTENDED_PROPERTIES  ' +CHAR(10)
							+ 'WHERE OBJECT_NAME(MAJOR_ID)= ''' + @TABLE_NAME + '''' +CHAR(10)
							+ 'AND MINOR_ID = 0' +CHAR(10)

--PRINT @STR_SQL
EXECUTE SP_EXECUTESQL @STR_SQL



SET @STR_SQL=  'SELECT ' +CHAR(10)
							+ 'SYSTBLS.NAME AS [TABLE NAME]' +CHAR(10)
							+ ',SYSCOLS.NAME AS [COLUMN NAME]' +CHAR(10)
							+ ' ,EXTPROP.VALUE AS [EXTENDED PROPERTY]' +CHAR(10)
							+  ',SYSTYP.NAME AS [DATA TYPE]' + CHAR(10)
							+ ',CASE WHEN SYSTYP.NAME IN(''NVARCHAR'',''NCHAR'') THEN (SYSCOLS.MAX_LENGTH / 2)' +CHAR(10)
							+           'WHEN SYSTYP.NAME IN(''VARCHAR'',''CHAR'') THEN SYSCOLS.MAX_LENGTH ELSE NULL END AS ''LENGTH OF COLUMN''' +CHAR(10)
							+ ',CASE WHEN SYSCOLS.IS_NULLABLE = 0 THEN ''NO''' +CHAR(10)
							+ '		  WHEN SYSCOLS.IS_NULLABLE = 1 THEN ''YES'' ELSE NULL END AS ''COLUMN IS NULLABLE''   ' +CHAR(10)
							+ ',SYSOBJ.CREATE_DATE AS [TABLE CREATE DATE]' +CHAR(10)
							+ ',SYSOBJ.MODIFY_DATE AS [TABLE MODIFY DATE]' +CHAR(10)
							+ 'FROM ' + @DB_NAME + '.SYS.TABLES AS SYSTBLS' +CHAR(10)
							+ 'LEFT JOIN ' +  @DB_NAME + '.SYS.EXTENDED_PROPERTIES AS EXTPROP' +CHAR(10)
							+ '		 ON EXTPROP.MAJOR_ID = SYSTBLS.[OBJECT_ID]' +CHAR(10)
							+ 'LEFT JOIN  ' + @DB_NAME + '.SYS.COLUMNS AS SYSCOLS' +CHAR(10)
							+ '		 ON EXTPROP.MAJOR_ID = SYSCOLS.[OBJECT_ID]' +CHAR(10)
							+ '		 AND EXTPROP.MINOR_ID = SYSCOLS.COLUMN_ID' +CHAR(10)
							+ 'LEFT JOIN  ' + @DB_NAME + '.SYS.OBJECTS AS SYSOBJ' +CHAR(10)
							+ '     	 ON SYSTBLS.[OBJECT_ID] = SYSOBJ.[OBJECT_ID]' +CHAR(10)
							+ 'INNER JOIN  ' + @DB_NAME + '.SYS.TYPES AS SYSTYP' +CHAR(10)
							+ '         ON SYSCOLS.USER_TYPE_ID = SYSTYP.USER_TYPE_ID' +CHAR(10)
						    + 'WHERE CLASS = 1 ' +CHAR(10)--OBJECT OR COLUMN' +CHAR(10)
						    + 'AND SYSTBLS.NAME = ''' + @TABLE_NAME + ''''+CHAR(10)
							  --AND SYSTBLS.NAME IS NOT NULL' +CHAR(10)
							  --AND SYSCOLS.NAME IS NOT NULL
--PRINT @STR_SQL

EXECUTE SP_EXECUTESQL @STR_SQL--, @STR_PARM, @XTYPE = @XTYPE OUTPUT


----SP_HELP_COLUMN  'GOODS'




go

CREATE PROCEDURE [dbo].[sp_help_revlogin] @login_name sysname = NULL AS
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
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa' AND
       isntname = 0  AND p.name not like '##%'
      order by p.name 

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
  --  SET @tmpstr = '-- Login: ' + @name
  --  PRINT @tmpstr
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
    PRINT @tmpstr + char(10) + 'GO'
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0




go


/*************************************************************************  
* 프로시저명  : dbo.sp_mon_blocking 
* 작성정보    : 2010-02-22 by 윤태진
* 관련페이지  :  
* 내용        :
* 수정정보    : 2010-02-22 by 최보라 수정
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_blocking]
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

/* USER DECLARE */

/* BODY */

select req.session_id as session_id
    ,req.blocking_session_id as blocking_session_id 
into #temp_blocking
from sys.dm_exec_requests req with(nolock)
where req.session_id > 50



IF exists(select top 1  * from #temp_blocking with(nolock) where blocking_session_id > 0 )
BEGIN
    select
         blocking.sid 
        ,blocking.blocked
        ,blocking.is_blocker
        ,blocking.cpu
        ,blocking.db_name
        ,blocking.object_name
        ,blocking.login_name
        ,blocking.host_name
        ,blocking.program_name
        ,blocking.query_text
        ,blocking.last_wait_type
        ,blocking.total_elapsed_time 
        ,blocking.status
        ,blocking.reads
        ,blocking.writes
        ,blocking.logical_reads
        ,blocking.scheduler_id
        ,blocking.wait_type
        ,blocking.wait_resource
        ,blocking.open_transaction_count

    from (
            select r.session_id  as sid 
            , r.blocking_session_id as blocked
            , 1 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            ,s.login_name
            ,s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2 + 1,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
            as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct blocking_session_id from #temp_blocking with(nolock) )
            
            union all 
            
            select r.session_id  as sid
            , r.blocking_session_id as blocked
            , 0 as is_blocker
            , r.status
    	    , r.cpu_time [cpu]
            , db_name(t1.dbid) as db_name 
            , object_schema_name(t1.objectid,t1.dbid) + '.' + object_name(t1.objectid,t1.dbid) [object_name]
            , s.login_name
            , s.host_name
            ,case when s.program_name like 'SQLAgent - TSQL JobStep%' then j.name else s.program_name end program_name 
            ,substring(t1.text,r.statement_start_offset/2,
            			(case when r.statement_end_offset = -1
            			then len(convert(nvarchar(max), t1.text)) * 2
            			else r.statement_end_offset end - r.statement_start_offset)/2)
                as query_text
            ,r.last_wait_type
            ,r.total_elapsed_time 
            ,r.reads
            ,r.writes
            ,r.logical_reads
            ,r.scheduler_id
            ,r.wait_type
            ,r.wait_resource
            ,r.open_transaction_count
            from sys.dm_exec_requests r with(nolock) 
            inner join sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id 
            left  join msdb.dbo.sysjobs j with(nolock) on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
            												substring(left(j.job_id,8),5,2) +
            												substring(left(j.job_id,8),3,2) +
            												substring(left(j.job_id,8),1,2))
            cross apply sys.dm_exec_sql_text (r.sql_handle) as t1
            where r.session_id in (select distinct session_id from #temp_blocking with(nolock) where blocking_session_id > 0 )
    )blocking

END

RETURN


go





CREATE procedure [dbo].[sp_mon_change_procedure]
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
go



CREATE FUNCTION [dbo].[fnc_removenumeric] (@str varchar(50))  
RETURNS varchar(50)  
AS  
BEGIN  
 DECLARE @seq int  
  
 SET @seq = 0  
  
 SET @str = REPLACE(@str, ' ', '')  
  
 WHILE @seq <= 9  
 BEGIN  
  
  SET @str = REPLACE(@str, convert(char(1), @seq), '')  
  
  SET @seq = @seq + 1  
  
 END  
  
 RETURN @str  
END  
go


CREATE PROCEDURE [dbo].[sp_mon_con_byhost]
AS
SET NOCOUNT ON 
    select dbo.fnc_removenumeric(hostname) as hostname, count(*) as connection_count
    FROM sys.sysprocesses with (nolock)  
    where spid > 50
    group by dbo.fnc_removenumeric(hostname)  
    order by count(*) desc  
;

go




/*************************************************************************  
* 프로시저명  : dbo.sp_mon_execute
* 작성정보    : 2010-02-11 by 최보라
* 관련페이지  :  
* 내용        : sysprocess조회
* 수정정보    : 2013-10-18 BY 최보라, 조건 정리
*************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_execute]
      @iswaitfor     tinyint = 0
     ,@plan          tinyint = 0
    
AS

SET NOCOUNT ON

if @plan is null
    set @plan = 0

if @plan = 0
begin
   	select 
           r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,r.wait_type
				,r.logical_reads
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,r.row_count
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(j.name, '') 
    				 else s.program_name end program_name 
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
				,r.percent_complete as '%'  
    			,r.plan_handle
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
            cross apply sys.dm_exec_sql_text(sql_handle) as qt
						left outer join msdb.dbo.sysjobs j
							on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
														substring(left(j.job_id,8),5,2) +
														substring(left(j.job_id,8),3,2) +
														substring(left(j.job_id,8),1,2))
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
              and  r.session_id != @@spid
    		order by r.cpu_time DESC
		
end		
if @plan = 1 -- Paln 쿼리.
begin
    
    
    
        select 
                r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
				,r.wait_type
				,r.logical_reads
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,r.row_count
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + j.name else s.program_name end program_name 
					,s.program_name
    			,qt.dbid
    			,qt.objectid
				,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
     WHEN 0 THEN 'Unspecified'
   WHEN 1 THEN 'ReadUncomitted'
        WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
                ,r.percent_complete as '%'     			
    			,r.plan_handle
    		    ,pt.query_plan
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
                 cross apply sys.dm_exec_sql_text(sql_handle) as qt
                 cross apply sys.dm_exec_query_plan(r.plan_handle) as pt
    		    left outer join msdb.dbo.sysjobs j
    			    on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
    												substring(left(j.job_id,8),5,2) +
    												substring(left(j.job_id,8),3,2) +
    												substring(left(j.job_id,8),1,2))
    		   
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
                  and  r.session_id != @@spid
    		order by r.cpu_time DESC
end
if @plan = 2  -- outer apply
begin
   select 
           r.session_id as [sid]
    			,r.blocking_session_id [blocked]
    			,r.status
    			,r.cpu_time [cpu]
    			,datediff(ss, r.start_time, getdate()) as [duration]
    			,db_name(qt.dbid) db_name
    			,r.wait_type
				,r.logical_reads
    			,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name]
    			,isnull(substring(qt.text,r.statement_start_offset / 2 + 1,                          
					(case when r.statement_end_offset = -1                               
				     then len(convert(nvarchar(max), qt.text)) * 2                               
					else r.statement_end_offset end - r.statement_start_offset) / 2), '')
    			as query_text
    			,r.last_wait_type
				,r.row_count
				,s.login_name
    			,s.host_name
    			,case when s.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + isnull(j.name, '') 
    				 else s.program_name end program_name 
    			,qt.dbid
    			,qt.objectid
                ,r.total_elapsed_time  
    			,r.reads
    			,r.writes
    			,r.scheduler_id
    			,CASE s.transaction_isolation_level 
                      WHEN 0 THEN 'Unspecified'
                      WHEN 1 THEN 'ReadUncomitted'
                      WHEN 2 THEN 'ReadCommitted'        
                      WHEN 3 THEN 'Repeatable'
                      WHEN 4 THEN 'Serializable'
                      WHEN 5 THEN 'Snapshot' END AS tx_level
    			,r.wait_resource
    			,r.open_transaction_count
    			,r.row_count
				,r.percent_complete as '%'  
    			,r.plan_handle
    		from sys.dm_exec_requests r
    		    inner join sys.dm_exec_sessions s on r.session_id = s.session_id
            outer apply sys.dm_exec_sql_text(sql_handle) as qt
						left outer join msdb.dbo.sysjobs j
							on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
														substring(left(j.job_id,8),5,2) +
														substring(left(j.job_id,8),3,2) +
														substring(left(j.job_id,8),1,2))
    		where ((@iswaitfor = 0 and wait_type <> 'WAITFOR')
				or (@iswaitfor =  1 and ISNULL(wait_type, '') <> 'WAITFOR') 
				or (@iswaitfor = 2 and isnull(wait_type,'')  = isnull(wait_type, '')) )
    		order by r.cpu_time DESC
		
end

go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_job_execute
* 작성정보    : 2013-09-05 by 유진호
* 관련페이지  :  
* 내용        : 수행 JOB 조회
* 수정정보    :
*************************************************************************/
CREATE PROC [dbo].[sp_mon_job_execute]
@ISWAITFOR INT = 0,
@PLAN INT = 0
AS
BEGIN
	SET NOCOUNT ON

	IF @PLAN = 0
	BEGIN
		SELECT           
		x.session_id as session_id,				
		COALESCE(x.blocking_session_id, 0) as blocked,
		CASE LEFT(x.program_name,15)
			WHEN 'SQLAgent - TSQL' THEN 
			(     select top 1 j.name from msdb.dbo.sysjobs (nolock) j
			inner join msdb.dbo.sysjobsteps (nolock) s on j.job_id=s.job_id
			where right(cast(s.job_id as nvarchar(50)),10) =RIGHT(substring(x.program_name,30,34),10) )
			WHEN 'SQL Server Prof' THEN 'SQL Server Profiler'
			ELSE x.program_name
		END as Program_name,
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(x.sql_handle)) as object_name,
		x.Status as status,
		x.TotalCPU as cpu,
		--x.duration as '분',
		CONVERT(nvarchar(30), getdate()-x.Start_time, 108) as Elap_time,
		db_name(x.database_id) as db_name,
		x.wait_type,
		--x.last_wait_type,
		x.logical_reads,				
		--x.totalElapsedTime as total_elapsed_time,
		x.totalReads as reads, -- total reads
		x.totalWrites as writes, --total writes			
		x.Writes_in_tempdb as tempdb,				
		(
			SELECT substring(text,x.statement_start_offset/2,
				(case when x.statement_end_offset = -1
				then len(convert(nvarchar(max), text)) * 2
				else x.statement_end_offset end - x.statement_start_offset+3)/2)
			FROM sys.dm_exec_sql_text(x.sql_handle)
		FOR XML PATH(''), TYPE
		) AS query_text,
		x.tx_level,
		x.wait_resource,
		x.Login_name,
		x.Host_name,
		x.Start_time,	
		x.open_transaction_count,
		x.percent_complete AS '%', 
		(
			SELECT
				p.text
				FROM
				(
					SELECT
						sql_handle,statement_start_offset,statement_end_offset
					FROM sys.dm_exec_requests r2
					WHERE
						r2.session_id = x.blocking_session_id
				) AS r_blocking
				CROSS APPLY
				(
					SELECT substring(text,r_blocking.statement_start_offset/2,
					(case when r_blocking.statement_end_offset = -1
					then len(convert(nvarchar(max), text)) * 2
					else r_blocking.statement_end_offset end - r_blocking.statement_start_offset+3)/2)
					FROM sys.dm_exec_sql_text(r_blocking.sql_handle)
					FOR XML PATH(''), TYPE
				) p (text)
		)  as blocking_text,				
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(
		(select top 1 sql_handle FROM sys.dm_exec_requests r3 WHERE r3.session_id =x.blocking_session_id))) as blocking_obj				
		FROM
		(
		SELECT
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				datediff(mi, r.start_time, getdate()) as [duration],
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END AS tx_level,
				SUM(cast(r.total_elapsed_time as bigint)) /1000 as totalElapsedTime, --CAST AS BIGINT to fix invalid data convertion when high activity
				SUM(cast(r.reads as bigint)) AS totalReads,
				SUM(cast(r.writes as bigint)) AS totalWrites,
				SUM(cast(r.cpu_time as bigint)) AS totalCPU,
				SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
		FROM sys.dm_exec_requests r
		JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
		JOIN sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id =tsu.request_id
		WHERE r.status IN ('running', 'runnable', 'suspended')
		GROUP BY
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END
		) x
		where x.session_id <> @@spid
		AND (program_name like '%SQL Job%'
		OR program_name like '%SQLCMD%')
		AND ((@iswaitfor = 1 and last_wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
		order by x.totalCPU desc
	END
	ELSE IF @PLAN = 1
	BEGIN
		SELECT           
		x.session_id as session_id,				
		COALESCE(x.blocking_session_id, 0) as blocked,
		CASE LEFT(x.program_name,15)
			WHEN 'SQLAgent - TSQL' THEN 
			(     select top 1 j.name from msdb.dbo.sysjobs (nolock) j
			inner join msdb.dbo.sysjobsteps (nolock) s on j.job_id=s.job_id
			where right(cast(s.job_id as nvarchar(50)),10) =RIGHT(substring(x.program_name,30,34),10) )
			WHEN 'SQL Server Prof' THEN 'SQL Server Profiler'
			ELSE x.program_name
		END as Program_name,
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(x.sql_handle)) as object_name,
		x.Status as status,
		x.TotalCPU as cpu,
		--x.duration as '분',
		CONVERT(nvarchar(30), getdate()-x.Start_time, 108) as Elap_time,
		db_name(x.database_id) as db_name,
		x.wait_type,
		--x.last_wait_type,
		x.logical_reads,				
		--x.totalElapsedTime as total_elapsed_time,
		x.totalReads as reads, -- total reads
		x.totalWrites as writes, --total writes			
		x.Writes_in_tempdb as tempdb,				
		(
			SELECT substring(text,x.statement_start_offset/2,
				(case when x.statement_end_offset = -1
				then len(convert(nvarchar(max), text)) * 2
				else x.statement_end_offset end - x.statement_start_offset+3)/2)
			FROM sys.dm_exec_sql_text(x.sql_handle)
		FOR XML PATH(''), TYPE
		) AS query_text,
		x.tx_level,
		x.wait_resource,
		x.Login_name,
		x.Host_name,
		x.Start_time,	
		x.open_transaction_count,
		x.percent_complete AS '%',
		pt.query_plan AS plan_handle,
		(
			SELECT
				p.text
				FROM
				(
					SELECT
						sql_handle,statement_start_offset,statement_end_offset
					FROM sys.dm_exec_requests r2
					WHERE
						r2.session_id = x.blocking_session_id
				) AS r_blocking
				CROSS APPLY
				(
					SELECT substring(text,r_blocking.statement_start_offset/2,
					(case when r_blocking.statement_end_offset = -1
					then len(convert(nvarchar(max), text)) * 2
					else r_blocking.statement_end_offset end - r_blocking.statement_start_offset+3)/2)
					FROM sys.dm_exec_sql_text(r_blocking.sql_handle)
					FOR XML PATH(''), TYPE
				) p (text)
		)  as blocking_text,				
		(SELECT object_schema_name(objectid,dbid) + '.' + object_name(objectid,dbid) FROM sys.dm_exec_sql_text(
		(select top 1 sql_handle FROM sys.dm_exec_requests r3 WHERE r3.session_id =x.blocking_session_id))) as blocking_obj				
		FROM
		(
		SELECT
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				datediff(mi, r.start_time, getdate()) as [duration],
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END AS tx_level,
				SUM(cast(r.total_elapsed_time as bigint)) /1000 as totalElapsedTime, --CAST AS BIGINT to fix invalid data convertion when high activity
				SUM(cast(r.reads as bigint)) AS totalReads,
				SUM(cast(r.writes as bigint)) AS totalWrites,
				SUM(cast(r.cpu_time as bigint)) AS totalCPU,
				SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
		FROM sys.dm_exec_requests r
		JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
		JOIN sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id =tsu.request_id
		WHERE r.status IN ('running', 'runnable', 'suspended')
		GROUP BY
				r.session_id,
				s.host_name,
				s.login_name,
				r.start_time,
				r.sql_handle,
				r.database_id,
				r.blocking_session_id,
				r.wait_type,
				r.last_wait_type,
				r.wait_resource,
				r.logical_reads,
				r.status,
				r.statement_start_offset,
				r.statement_end_offset,
				s.program_name,
				r.percent_complete,
				r.open_transaction_count,
				r.plan_handle,
				CASE s.transaction_isolation_level 
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'        
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot' END
		) x
		CROSS APPLY sys.dm_exec_query_plan(x.plan_handle) as pt
		where x.session_id <> @@spid
		AND (program_name like '%SQL Job%'
		OR program_name like '%SQLCMD%')
		AND ((@iswaitfor = 1 and last_wait_type  = wait_type) or  (wait_type <> 'WAITFOR'))
		order by x.totalCPU desc
	END
END



go





/*************************************************************************  
* 프로시저명  : dbo.sp_mon_longjob
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 1시간 이상  경과한 job 목록
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_longjob]
    @duration        int = 60
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
select 'KILL ' + cast(s.session_id as varchar) as 'kill', 
               s.session_id,
	           j.name as job_name, 
	           cast(datediff(mi, s.login_time, getdate()) as varchar)+ '분' as duration
	           , s.login_time
	           , s.host_name
 	           , s.client_interface_name
	from sys.dm_exec_sessions as s with (nolock)
        inner join msdb.dbo.sysjobs j with (nolock)
        on substring(s.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
									    substring(left(j.job_id,8),5,2) +
									    substring(left(j.job_id,8),3,2) +
									    substring(left(j.job_id,8),1,2))
where s.session_id > 50  and datediff(mi, s.login_time, getdate()) >= @duration
order by datediff(mi, s.login_time, getdate()) desc

RETURN






go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_memory_grant
* 작성정보    : 2013-11-07 by 서은미
* 관련페이지  :  
* 내용        : [Memory] 실행되는 세션, 스케줄에 할당되는 메모리 정보
* 수정정보    : 
*************************************************************************/
CREATE PROC [dbo].[sp_mon_memory_grant]
AS
select req.session_id 
	,req.status, req.cpu_time
	,datediff(ss, req.start_time, getdate()) duration
	,mem.granted_memory_kb granted_memory
	,db_name(qt.dbid) as db_name			
	,object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name] 	
	,CASE WHEN   req.statement_end_offset = -1 and ( (req.statement_start_offset )  > DATALENGTH (qt.text) )
	THEN  convert(varchar(4000), 
    				substring(isnull(qt.text, '') 
    				, 1, ( ( DATALENGTH (qt.text) - 1 )/2 ) + 1 ) )
	ELSE  convert(varchar(4000), substring(isnull(qt.text, '') 
    		, (req.statement_start_offset / 2) + 1
    		, (( case when req.statement_end_offset = -1 then DATALENGTH (qt.text) else req.statement_end_offset end	
    				- req.statement_start_offset ) /2 ) + 1) )
	END  as query_text
	, ses.host_name
	 ,ses.program_name
	--,case when ses.program_name like 'SQLAgent - TSQL JobStep%' then 'SQLAgent - ' + j.name else ses.program_name end program_name 
	,ses.login_name	
	,mem.timeout_sec
	,mem.dop, mem.grant_time, mem.requested_memory_kb, (req.granted_query_memory *8 ) as req_granted_query_memory
	,mem.used_memory_kb
	--,mem.max_used_memory_kb
	,mem.query_cost
	--,mem.group_id, mem.pool_id	
	--,mem.queue_id 
	--,mem.wait_order 
	--, req.request_id, ses.host_process_id
from sys.dm_exec_requests  as req with(nolock)
	inner join sys.dm_exec_sessions as ses with (nolock) on req.session_id = ses.session_id
	left join sys.dm_exec_query_memory_grants as mem with(nolock) on req.request_id = mem.request_id
		and req.session_id = mem.session_id and req.scheduler_id = mem.scheduler_id
	outer apply sys.dm_exec_sql_text(req.sql_handle) as qt 
	--left outer join msdb.dbo.sysjobs j
 --   			    on substring(ses.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
 --   												substring(left(j.job_id,8),5,2) +
 --   												substring(left(j.job_id,8),3,2) +
 --   												substring(left(j.job_id,8),1,2))
where req.session_id > 50  
       AND req.cpu_time > 100 
order by mem.granted_memory_kb desc



go





/*************************************************************************  
* 프로시저명  : dbo.sp_mon_mirroring_status
* 작성정보    : 2010-02-22
* 관련페이지  :  
* 내용        : 미러링 연결 상태
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_mirroring_status]

AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT 
      DB_NAME(database_id) AS 'DatabaseName' 
       , database_id                                               -- 데이터베이스ID 
       , mirroring_guid                                            -- 미러링파트너관계의ID
       , CASE mirroring_state                                      -- 미러링세션의상태
             WHEN 0 THEN '일시중지됨'
             WHEN 1 THEN '연결끊김'
             WHEN 2 THEN '동기화중'
             WHEN 3 THEN '장애조치(Failover) 보류중'
             WHEN 4 THEN '동기화됨'
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_state   
    , mirroring_role_desc    
       , CASE mirroring_safety_level                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없는상태'
             WHEN 1 THEN 'Off[비동기]'
             WHEN 2 THEN 'Full[동기]'          
             WHEN null THEN '데이터베이스가온라인이아님'    
         END AS mirroring_safety_level       
    , mirroring_safety_sequence --트랜잭션보안수준변경내용에대한시퀀스번호를업데이트합니다.
    , mirroring_role_sequence --장애조치또는강제서비스로인해미러링파트너가주서버및미러서버역할을전환한횟수입니다. 
    , mirroring_partner_instance
    , mirroring_witness_name
    --, mirroring_witness_state_desc
       ,CASE mirroring_witness_state                                     -- 미러링세션의상태
             WHEN 0 THEN '알수없음'
             WHEN 1 THEN '연결됨'
             WHEN 2 THEN '연결끊김'             
             WHEN null THEN '미러링모니터가존재하지않거나데이터베이스가온라인이아님'       
         END AS mirroring_witness_state    
    , mirroring_failover_lsn --장애조치후에두파트너는mirroring_failover_lsn을새미러서버가새미러데이터베이스와새주데이터베이스와의동기화를시작하는조정지점
FROM sys.database_mirroring  as dm WITH(NOLOCK)
WHERE mirroring_guid IS NOT NULL;

RETURN






go





/*************************************************************************  
* 프로시저명  : dbo.sp_mon_replication_perf 
* 작성정보    : 2010-02-19 by 이성표
* 관련페이지  :  
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_replication_perf]
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */
SELECT instance_name, 
  SUM(CASE counter_name WHEN 'Dist:Delivery Latency' THEN cntr_value ELSE 0 END) AS delivery_Latency,
  SUM(CASE counter_name WHEN 'Dist:Delivered Cmds/sec' THEN cntr_value ELSE 0 END) AS delivery_cmds,
  SUM(CASE counter_name WHEN 'Dist:Delivered Trans/sec' THEN cntr_value ELSE 0 END) AS delivery_trans  
  FROM sys.dm_os_performance_counters with (nolock)
WHERE (object_name like '%Replication Dist.%')
GROUP BY instance_name

RETURN






go




/*************************************************************************                
* 프로시저명  : dbo.sp_mon_replication_status               
* 작성정보    : 2009-06-15  인성환                
* 관련페이지  :                
* 내용        : 복제 에이전트 기록    
* 수정정보    : 2009-12-07 최보라 agent_id 추가             
**************************************************************************/      
  CREATE PROCEDURE [dbo].[sp_mon_replication_status]  
AS  
set nocount on  
declare @v_agentid_table table (  
 i int identity(1,1) primary key,  
 agent_id int);  
  
declare @v_repl_hist table(
 agent_id   int,  
 agent_name nvarchar(100) primary key,  
 runstatus nvarchar(10),  
 [time]  datetime,  
 delivery_latency int,  
 comments nvarchar(4000),  
 duration int,  
 delivery_rate float,  
 delivered_transactions int,  
 delivered_commands int,  
 average_commands int,  
 error_id int,  
 current_delivery_rate float,  
 current_delivery_latency int,  
 total_delivered_commands int);  
  
declare @vloop int  
set @vloop = 1  
insert into @v_agentid_table (agent_id)  
select  
 agent.id agent_id  
from msdb.dbo.sysjobs job with (nolock)  
inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
 on job.name = agent.name  
  
while (@vloop <= (select max(i) from @v_agentid_table))  
begin  
insert into @v_repl_hist  
select top 1  
     temp.agent_id,
     agent.name,  
     case hist.runstatus when 1 then '시작'  
          when 2 then '성공'  
          when 3 then '진행중'  
          when 4 then '유휴상태'  
          when 5 then '다시시도'  
          when 6 then '실패' end runstatus,  
     'time' = sys.fn_replformatdatetime(time),  
     hist.delivery_latency,  
     hist.comments,  
     hist.duration,  
     hist.delivery_rate,  
     hist.delivered_transactions,  
     hist.delivered_commands,  
     hist.average_commands,  
     hist.error_id,  
     hist.current_delivery_rate,  
     hist.current_delivery_latency,  
     hist.total_delivered_commands  
from msdb.dbo.sysjobs job with (nolock)  
    inner join Distribution.dbo.MSdistribution_agents agent with (nolock)  
     on job.name = agent.name  
    inner join Distribution.dbo.MSdistribution_history hist with (nolock)  
     on agent.id = hist.agent_id  
    inner join @v_agentid_table temp  
     on agent.id = temp.agent_id  
where temp.i = @vloop  
order by hist.timestamp desc, hist.delivery_latency desc
 set @vloop = @vloop + 1  
end;  
  
select @@servername as distribute_server_name , * from @v_repl_hist  
order by delivery_latency desc 
go

/*************************************************************************  
* 프로시저명  : dbo.sp_mon_tempuse 
* 작성정보    : 2010-02-19 by choi bo ra
* 관련페이지  :  
* 내용        :
* 수정정보    : 2013-09-25 by choi bo ra
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_tempuse]
    @type       int = 0
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */

/* BODY */

IF @type = 1
BEGIN
    select  
         u.session_id,    
        s.host_name,    
        s.login_name,  
        s.status,  
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
    where u.database_id = 2    
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name   
    order by 8 desc  
END
ELSE IF @type = 0
BEGIN
    select  
        u.session_id, 
        s.host_name,    
        s.login_name,  
        s.status,  
        object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid) [object_name],
        s.program_name, 
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count)*8 tempdb_space_alloc_kB,    
        sum(u.user_objects_dealloc_page_count+u.internal_objects_dealloc_page_count)*8 tempdb_space_dealloc_kB,   
        sum(u.user_objects_alloc_page_count+u.internal_objects_alloc_page_count -u.user_objects_dealloc_page_count - u.internal_objects_dealloc_page_count)*8 remaining_tempdb_space_alloc_kB    
    from sys.dm_db_session_space_usage as u   
        join sys.dm_exec_sessions as s on s.session_id = u.session_id   
        left join sys.dm_exec_requests r on s.session_id = r.session_id
        outer  apply sys.dm_exec_sql_text(sql_handle) as qt
    where u.database_id = 2  and u.session_id > 50 --and r.wait_type <> 'WAITFOR'
    group by u.session_id, s.host_name,  s.status, s.login_name, s.program_name 
        ,  object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)
    order by  9 desc  

END


RETURN
go





/*************************************************************************  
* 프로시저명  : dbo.sp_mon_top_cpu 
* 작성정보    : 2010-02-22 by 최보라
* 관련페이지  :  
* 내용        : 2초간 CPU 높은 쿼리
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE [dbo].[sp_mon_top_cpu]
     @row_count  int = 15
    ,@delay_time datetime  = '00:00:02'

AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SET LOCK_TIMEOUT 10000

/* USER DECLARE */

/* BODY */
        -- insert sys.dm_exec_requests into temp table !
		select 
    		 session_id
    		,request_id 
    		,connection_id
    		,sql_handle
    		,cpu_time
    		,(writes + reads) as physical_io 
    	into #tmp_requests 
		from sys.dm_exec_requests with(nolock) 
		
	
	  -- delay with parameter

		WAITFOR DELAY @delay_time
		
		
		----------------------------------------------------------------
	  -- find 
	  ----------------------------------------------------------------
	    select top(@row_count) 
    			req.session_id as sid
                ,case when qt.objectid is null then
    			    isnull(substring(qt.text,req.statement_start_offset / 2 + 1,                          
					    (case when req.statement_end_offset = -1                               
				         then len(convert(nvarchar(max), qt.text)) * 2   
                         else req.statement_end_offset end - req.statement_start_offset) / 2), '')
                    else object_schema_name(qt.objectid,qt.dbid) + '.' + object_name(qt.objectid,qt.dbid)  end [object_name]
    			,(req.cpu_time - tmp.cpu_time) as cpu_gap
    			, req.cpu_time
    			, req.status
    			, req.last_wait_type
    			,(req.reads + req.writes) as physical_io
    			,req.logical_reads
    			,session.login_name 
    			,session.host_name
    			,req.start_time
    			,case when session.program_name like 'SQLAgent - TSQL JobStep%' then j.name else session.program_name end program_name 
    		    --,req.sql_handle
    		    ,substring(qt.text,req.statement_start_offset/2,
				(case when req.statement_end_offset = -1
				then len(convert(nvarchar(max), qt.text)) * 2
				else req.statement_end_offset end - req.statement_start_offset)/2)
				as query_text
    		    ,req.plan_handle
				,req.statement_start_offset
				,req.statement_end_offset
		from sys.dm_exec_requests req with(nolock)
			inner join sys.dm_exec_sessions session with(nolock) on req.session_id = session.session_id
			inner join #tmp_requests tmp with(nolock) 
			    on ( req.session_id = tmp.session_id and  req.request_id = tmp.request_id)
			left outer join msdb.dbo.sysjobs j
	            on substring(session.program_name,32,8) = (substring(left(j.job_id,8),7,2) +
										substring(left(j.job_id,8),5,2) +
										substring(left(j.job_id,8),3,2) +
										substring(left(j.job_id,8),1,2))
			cross apply sys.dm_exec_sql_text(req.sql_handle) as qt
			
		where session.is_user_process = 1 
		    and session.host_name <> @@servername and object_name(qt.objectid,qt.dbid)  != 'sp_mon_top_cpu'
		order by (req.cpu_time - tmp.cpu_time) desc , req.cpu_time desc 


DROP TABLE  #tmp_requests 
RETURN
go




create procedure [dbo].[sp_spaceused2] --- 1996/08/20 17:01
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
go

/*********************************************************************************************
Who Is Active? v11.11 (2012-03-22)
(C) 2007-2012, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx
"Beta" Builds: http://sqlblog.com/files/folders/beta/tags/who+is+active/default.aspx

Donate! Support this project: http://tinyurl.com/WhoIsActiveDonate

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
CREATE PROC [dbo].[sp_WhoIsActive]
(
--~
	--Filters--Both inclusive and exclusive
	--Set either filter to '' to disable
	--Valid filter types are: session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used to indicate "all" sessions
	--All other filter types support % or _ as wildcards
	@filter sysname = '',
	@filter_type VARCHAR(10) = 'session',
	@not_filter sysname = '',
	@not_filter_type VARCHAR(10) = 'session',

	--Retrieve data about the calling session?
	@show_own_spid BIT = 0,

	--Retrieve data about system sessions?
	@show_system_spids BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@show_sleeping_spids TINYINT = 1,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Get information on active tasks, based on three interest levels
	--Level 0 does not pull any task-related information
	--Level 1 is a lightweight mode that pulls the top non-CXPACKET wait, giving preference to blockers
	--Level 2 pulls all available task-based metrics, including: 
	--number of active tasks, current wait stats, physical I/O, context switches, and blocker information
	@get_task_info TINYINT = 1,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Get additional non-performance-related information about the session or request
	--text_size, language, date_format, date_first, quoted_identifier, arithabort, ansi_null_dflt_on, 
	--ansi_defaults, ansi_warnings, ansi_padding, ansi_nulls, concat_null_yields_null, 
	--transaction_isolation_level, lock_timeout, deadlock_priority, row_count, command_type
	--
	--If a SQL Agent job is running, an subnode called agent_info will be populated with some or all of
	--the following: job_id, job_name, step_id, step_name, msdb_query_error (in the event of an error)
	--
	--If @get_task_info is set to 2 and a lock wait is detected, a subnode called block_info will be
	--populated with some or all of the following: lock_type, database_name, object_id, file_id, hobt_id, 
	--applock_hash, metadata_resource, metadata_class_id, object_name, schema_name
	@get_additional_info BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	--Also enables task_info Level 1, if @get_task_info is set to 0
	@find_block_leaders BIT = 0,

	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',

	--Column(s) by which to sort output, optionally with sort directions. 
		--Valid column choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_allocations,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_allocations_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--tasks, tran_start_time, open_tran_count, blocking_session_id, blocked_session_count,
		--percent_complete, host_name, login_name, database_name, start_time, login_time
		--
		--Note that column names in the list must be bracket-delimited. Commas and/or white
		--space are not required. 
	@sort_order VARCHAR(500) = '[start_time] ASC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables outfput format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,

	--Help! What do I do?
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time since the last batch completed

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NULL
Non-Formatted:	[reads] [bigint] NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NULL
Non-Formatted:	[physical_reads] [bigint] NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NULL
Non-Formatted:	[writes] [bigint] NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_allocations] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations] [bigint] NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NULL
Non-Formatted:	[tempdb_current] [bigint] NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NULL
Non-Formatted:	[CPU] [int] NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_allocations_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)

Formatted/Non:	[wait_info] [nvarchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	If wait type E is CXPACKET, the nodeId from the query plan will be identified

Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [nvarchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:wB (C kB)
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	C is the number of log kilobytes consumed by the log records

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [smallint] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [nvarchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [nvarchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [sysname] NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [sysname] NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [sysname] NULL
	Shows the connected database

Formatted/Non:	[program_name] [sysname] NULL
	Shows the reported program/application name

Formatted/Non:	[additional_info] [xml] NULL
	(Requires @get_additional_info option)
	Returns additional non-performance-related session/request information
	If the script finds a SQL Agent job running, the name of the job and job step will be reported
	If @get_task_info = 2 and the script finds a lock wait, the locked object will be reported

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the last batch completed

Formatted/Non:	[login_time] [datetime] NOT NULL
	Shows the time that the session connected

Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN;
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET ANSI_WARNINGS ON;
	SET NUMERIC_ROUNDABORT OFF;
	SET ARITHABORT ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @not_filter IS NULL
		OR @not_filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @show_system_spids IS NULL
		OR @show_sleeping_spids IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_transaction_info IS NULL
		OR @get_task_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @get_additional_info IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @sort_order IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type = 'session' AND @not_filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @show_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @show_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @get_task_info NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_task_info are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE 
			@header VARCHAR(MAX),
			@params VARCHAR(MAX),
			@outputs VARCHAR(MAX);

		SELECT 
			@header =
				REPLACE
				(
					REPLACE
					(
						CONVERT
						(
							VARCHAR(MAX),
							SUBSTRING
							(
								t.text, 
								CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94,
								CHARINDEX(REPLICATE('*', 93) + '/', t.text) - (CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94)
							)
						),
						CHAR(13)+CHAR(10),
						CHAR(13)
					),
					'	',
					''
				),
			@params =
				CHAR(13) +
					REPLACE
					(
						REPLACE
						(
							CONVERT
							(
								VARCHAR(MAX),
								SUBSTRING
								(
									t.text, 
									CHARINDEX('--~', t.text) + 5, 
									CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
								)
							),
							CHAR(13)+CHAR(10),
							CHAR(13)
						),
						'	',
						''
					),
				@outputs = 
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								REPLACE
								(
									CONVERT
									(
										VARCHAR(MAX),
										SUBSTRING
										(
											t.text, 
											CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
											CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
										)
									),
									CHAR(9),
									CHAR(255)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13)
		FROM sys.dm_exec_requests AS r
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
		WHERE
			r.session_id = @@SPID;

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@header) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		)
		SELECT
			RTRIM(LTRIM(
				SUBSTRING
				(
					@header,
					number + 1,
					CHARINDEX(CHAR(13), @header, number + 1) - number - 1
				)
			)) AS [------header---------------------------------------------------------------------------------------------------------------]
		FROM numbers
		WHERE
			SUBSTRING(@header, number, 1) = CHAR(13);

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@params) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CASE
					WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
					ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params)) 
				END AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY
						CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
						SUBSTRING(@params, number+1, 1)
					ORDER BY 
						number
				) AS group_order
			FROM numbers
			WHERE
				SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				MIN
				(
					CASE
						WHEN token LIKE '@%' THEN token
						ELSE NULL
					END
				) AS parameter,
				MIN
				(
					CASE
						WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
						ELSE NULL
					END
				) AS description,
				param_group,
				group_order
			FROM tokens
			WHERE
				NOT 
				(
					token = '' 
					AND group_order > 1
				)
			GROUP BY
				param_group,
				group_order
		)
		SELECT
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
				WHEN param_group = MAX(param_group) OVER() THEN parameter
				ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			param_group, 
			group_order;
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@outputs) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@outputs,
						number + 1,
						CASE
							WHEN 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) < 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs))
								THEN COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) - number - 1
							ELSE
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs)) - number - 1
						END
					)
				)) AS token,
				number,
				COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) AS output_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY 
						COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs))
					ORDER BY
						number
				) AS output_group_order
			FROM numbers
			WHERE
				SUBSTRING(@outputs, number, 10) = CHAR(13) + 'Formatted'
				OR SUBSTRING(@outputs, number, 2) = CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2
		),
		output_tokens AS
		(
			SELECT 
				*,
				CASE output_group_order
					WHEN 2 THEN MAX(CASE output_group_order WHEN 1 THEN token ELSE NULL END) OVER (PARTITION BY output_group)
					ELSE ''
				END COLLATE Latin1_General_Bin2 AS column_info
			FROM tokens
		)
		SELECT
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)-1)



					END
				ELSE ''
			END AS formatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, LEN(column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
					END
				ELSE ''
			END AS formatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX('>', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:
', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
								ELSE
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:'
, column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
							END
					END
				ELSE ''
			END AS unformatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN ''
								ELSE
									SUBSTRING(column_info, CHARINDEX(']', column_info, CHARINDEX('Non-Formatted:', column_info))+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
							END
					END
				ELSE ''
			END AS unformatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE REPLACE(token, CHAR(255) COLLATE Latin1_General_Bin2, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM output_tokens
		WHERE
			NOT 
			(
				output_group_order = 1 
				AND output_group = LEN(@outputs)
			)
		ORDER BY
			output_group,
			CASE output_group_order
				WHEN 1 THEN 99
				ELSE output_group_order
			END;

		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@output_column_list))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output IN (1, 2)
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output IN (1, 2)
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_allocations]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
				AND @get_task_info = 2
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_allocations_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
				AND @get_task_info = 2
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[additional_info]', 40
			WHERE
				@get_additional_info = 1
			UNION ALL
			SELECT '[start_time]', 41
			UNION ALL
			SELECT '[login_time]', 42
			UNION ALL
			SELECT '[request_id]', 43
			UNION ALL
			SELECT '[collection_time]', 44
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN;
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN;
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN;
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@sort_order))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@sort_order,
					number + 1,
					CHARINDEX(']', @sort_order, number) - number - 1
				) + '|]' AS token,
			SUBSTRING
			(
				@sort_order,
				CHARINDEX(']', @sort_order, number) + 1,
				COALESCE(NULLIF(CHARINDEX('[', @sort_order, CHARINDEX(']', @sort_order, number)), 0), LEN(@sort_order)) - CHARINDEX(']', @sort_order, number)
			) AS next_chunk,
			number
		FROM numbers
		WHERE
			SUBSTRING(@sort_order, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name +
				CASE
					WHEN tokens.next_chunk LIKE '%asc%' THEN ' ASC'
					WHEN tokens.next_chunk LIKE '%desc%' THEN ' DESC'
					ELSE ''
				END AS column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number
			) AS r,
			tokens.number
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name
			UNION ALL
			SELECT '[physical_io]'
			UNION ALL
			SELECT '[reads]'
			UNION ALL
			SELECT '[physical_reads]'
			UNION ALL
			SELECT '[writes]'
			UNION ALL
			SELECT '[tempdb_allocations]'
			UNION ALL
			SELECT '[tempdb_current]'
			UNION ALL
			SELECT '[CPU]'
			UNION ALL
			SELECT '[context_switches]'
			UNION ALL
			SELECT '[used_memory]'
			UNION ALL
			SELECT '[physical_io_delta]'
			UNION ALL
			SELECT '[reads_delta]'
			UNION ALL
			SELECT '[physical_reads_delta]'
			UNION ALL
			SELECT '[writes_delta]'
			UNION ALL
			SELECT '[tempdb_allocations_delta]'
			UNION ALL
			SELECT '[tempdb_current_delta]'
			UNION ALL
			SELECT '[CPU_delta]'
			UNION ALL
			SELECT '[context_switches_delta]'
			UNION ALL
			SELECT '[used_memory_delta]'
			UNION ALL
			SELECT '[tasks]'
			UNION ALL
			SELECT '[tran_start_time]'
			UNION ALL
			SELECT '[open_tran_count]'
			UNION ALL
			SELECT '[blocking_session_id]'
			UNION ALL
			SELECT '[blocked_session_count]'
			UNION ALL
			SELECT '[percent_complete]'
			UNION ALL
			SELECT '[host_name]'
			UNION ALL
			SELECT '[login_name]'
			UNION ALL
			SELECT '[database_name]'
			UNION ALL
			SELECT '[start_time]'
			UNION ALL
			SELECT '[login_time]'
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@sort_order = COALESCE(z.sort_order, '')
	FROM
	(
		SELECT
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						number
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			) AS sort_order
	) AS z;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NOT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NULL,
		physical_reads BIGINT NULL,
		writes BIGINT NULL,
		tempdb_allocations BIGINT NULL,
		tempdb_current BIGINT NULL,
		CPU INT NULL,
		thread_CPU_snapshot BIGINT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info NVARCHAR(4000) NULL,
		locks XML NULL,
		transaction_id BIGINT NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes NVARCHAR(4000) NULL,
		open_tran_count SMALLINT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name sysname NULL,
		login_name sysname NOT NULL,
		database_name sysname NULL,
		program_name sysname NULL,
		additional_info XML NULL,
		start_time DATETIME NOT NULL,
		login_time DATETIME NULL,
		last_request_start_time DATETIME NULL,
		PRIMARY KEY CLUSTERED (session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON),
		UNIQUE NONCLUSTERED (transaction_id, session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON)
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_transaction_id ON #sessions (transaction_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		DECLARE @first_collection_ms_ticks BIGINT;
		DECLARE @last_collection_start DATETIME;

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.database_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				s.request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name,
				CONVERT(NVARCHAR(2048), NULL) AS query_error
			INTO #locks
			FROM
			(
				SELECT
					sp.spid AS session_id,
					CASE sp.status
						WHEN 'sleeping' THEN CONVERT(INT, 0)
						ELSE sp.request_id
					END AS request_id,
					CASE sp.status
						WHEN 'sleeping' THEN sp.last_batch
						ELSE COALESCE(req.start_time, sp.last_batch)
					END AS start_time,
					sp.dbid
				FROM sys.sysprocesses AS sp
				OUTER APPLY
				(
					SELECT TOP(1)
						CASE
							WHEN 
							(
								sp.hostprocess > ''
								OR r.total_elapsed_time < 0
							) THEN
								r.start_time
							ELSE
								DATEADD
								(
									ms, 
									1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())), 
									DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
								)
						END AS start_time
					FROM sys.dm_exec_requests AS r
					WHERE
						r.session_id = sp.spid
						AND r.request_id = sp.request_id
				) AS req
				WHERE
					--Process inclusive filter
					1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(SMALLINT, @filter) = 0
												OR sp.spid = CONVERT(SMALLINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
					--Process exclusive filter
					AND 0 =
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN sp.spid = CONVERT(SMALLINT, @not_filter) THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @not_filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 0
						END
					AND 
					(
						@show_own_spid = 1
						OR sp.spid <> @@SPID
					)
					AND 
					(
						@show_system_spids = 1
						OR sp.hostprocess > ''
					)
					AND sp.ecid = 0
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), N'(null)') AS database_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = s.request_id
			OPTION (HASH GROUP);

			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_database_name ON #locks (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			CONVERT(VARCHAR(MAX), '') +
			'DECLARE @blocker BIT;
			SET @blocker = 0;
			DECLARE @i INT;
			SET @i = 2147483647;

			DECLARE @sessions TABLE
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				login_time DATETIME,
				last_request_end_time DATETIME,
				status VARCHAR(30),
				statement_start_offset INT,
				statement_end_offset INT,
				sql_handle BINARY(20),
				host_name NVARCHAR(128),
				login_name NVARCHAR(128),
				program_name NVARCHAR(128),
				database_id SMALLINT,
				memory_usage INT,
				open_tran_count SMALLINT, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0 
						OR @find_block_leaders = 1 
					) THEN
						'wait_type NVARCHAR(32),
						wait_resource NVARCHAR(256),
						wait_time BIGINT, 
						'
					ELSE 
						''
				END +
				'blocked SMALLINT,
				is_user_process BIT,
				cmd VARCHAR(32),
				PRIMARY KEY CLUSTERED (session_id, request_id) WITH (IGNORE_DUP_KEY = ON)
			);

			DECLARE @blockers TABLE
			(
				session_id INT NOT NULL PRIMARY KEY
			);

			BLOCKERS:;

			INSERT @sessions
			(
				session_id,
				request_id,
				login_time,
				last_request_end_time,
				status,
				statement_start_offset,
				statement_end_offset,
				sql_handle,
				host_name,
				login_name,
				program_name,
				database_id,
				memory_usage,
				open_tran_count, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0
						OR @find_block_leaders = 1 
					) THEN
						'wait_type,
						wait_resource,
						wait_time, 
						'
					ELSE
						''
				END +
				'blocked,
				is_user_process,
				cmd 
			)
			SELECT TOP(@i)
				spy.session_id,
				spy.request_id,
				spy.login_time,
				spy.last_request_end_time,
				spy.status,
				spy.statement_start_offset,
				spy.statement_end_offset,
				spy.sql_handle,
				spy.host_name,
				spy.login_name,
				spy.program_name,
				spy.database_id,
				spy.memory_usage,
				spy.open_tran_count,
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0  
						OR @find_block_leaders = 1 
					) THEN
						'spy.wait_type,
						CASE
							WHEN
								spy.wait_type LIKE N''PAGE%LATCH_%''
								OR spy.wait_type = N''CXPACKET''
								OR spy.wait_type LIKE N''LATCH[_]%''
								OR spy.wait_type = N''OLEDB'' THEN
									spy.wait_resource
							ELSE
								NULL
						END AS wait_resource,
						spy.wait_time, 
						'
					ELSE
						''
				END +
				'spy.blocked,
				spy.is_user_process,
				spy.cmd
			FROM
			(
				SELECT TOP(@i)
					spx.*, 
					' +
					CASE
						WHEN 
						(
							@get_task_info <> 0 
							OR @find_block_leaders = 1 
						) THEN
							'ROW_NUMBER() OVER
							(
								PARTITION BY
									spx.session_id,
									spx.request_id
								ORDER BY
									CASE
										WHEN spx.wait_type LIKE N''LCK[_]%'' THEN 
											1
										ELSE
											99
									END,
									spx.wait_time DESC,
									spx.blocked DESC
							) AS r 
							'
						ELSE 
							'1 AS r 
							'
					END +
				'FROM
				(
					SELECT TOP(@i)
						sp0.session_id,
						sp0.request_id,
						sp0.login_time,
						sp0.last_request_end_time,
						LOWER(sp0.status) AS status,
						CASE
							WHEN sp0.cmd = ''CREATE INDEX'' THEN
								0
							ELSE
								sp0.stmt_start
						END AS statement_start_offset,
						CASE
							WHEN sp0.cmd = N''CREATE INDEX'' THEN
								-1
							ELSE
								COALESCE(NULLIF(sp0.stmt_end, 0), -1)
						END AS statement_end_offset,
						sp0.sql_handle,
						sp0.host_name,
						sp0.login_name,
						sp0.program_name,
						sp0.database_id,
						sp0.memory_usage,
						sp0.open_tran_count, 
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0 
								OR @find_block_leaders = 1 
							) THEN
								'CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_type
									ELSE
										NULL
								END AS wait_type,
								CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN 
										sp0.wait_resource
									ELSE
										NULL
								END AS wait_resource,
								CASE
									WHEN sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_time
									ELSE
										0
								END AS wait_time, 
								'
							ELSE
								''
						END +
						'sp0.blocked,
						sp0.is_user_process,
						sp0.cmd
					FROM
					(
						SELECT TOP(@i)
							sp1.session_id,
							sp1.request_id,
							sp1.login_time,
							sp1.last_request_end_time,
							sp1.status,
							sp1.cmd,
							sp1.stmt_start,
							sp1.stmt_end,
							MAX(NULLIF(sp1.sql_handle, 0x00)) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS sql_handle,
							sp1.host_name,
							MAX(sp1.login_name) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS login_name,
							sp1.program_name,
							sp1.database_id,
							MAX(sp1.memory_usage)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS memory_usage,
							MAX(sp1.open_tran_count)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS open_tran_count,
							sp1.wait_type,
							sp1.wait_resource,
							sp1.wait_time,
							sp1.blocked,
							sp1.hostprocess,
							sp1.is_user_process
						FROM
						(
							SELECT TOP(@i)
								sp2.spid AS session_id,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END AS request_id,
								MAX(sp2.login_time) AS login_time,
								MAX(sp2.last_batch) AS last_request_end_time,
								MAX(CONVERT(VARCHAR(30), RTRIM(sp2.status)) COLLATE Latin1_General_Bin2) AS status,
								MAX(CONVERT(VARCHAR(32), RTRIM(sp2.cmd)) COLLATE Latin1_General_Bin2) AS cmd,
								MAX(sp2.stmt_start) AS stmt_start,
								MAX(sp2.stmt_end) AS stmt_end,
								MAX(sp2.sql_handle) AS sql_handle,
								MAX(CONVERT(sysname, RTRIM(sp2.hostname)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS host_name,
								MAX(CONVERT(sysname, RTRIM(sp2.loginame)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS login_name,
								MAX
								(
									CASE
										WHEN blk.queue_id IS NOT NULL THEN
											N''Service Broker
												database_id: '' + CONVERT(NVARCHAR, blk.database_id) +
												N'' queue_id: '' + CONVERT(NVARCHAR, blk.queue_id)
										ELSE
											CONVERT
											(
												sysname,
												RTRIM(sp2.program_name)
											)
									END COLLATE SQL_Latin1_General_CP1_CI_AS
								) AS program_name,
								MAX(sp2.dbid) AS database_id,
								MAX(sp2.memusage) AS memory_usage,
								MAX(sp2.open_tran) AS open_tran_count,
								RTRIM(sp2.lastwaittype) AS wait_type,
								RTRIM(sp2.waitresource) AS wait_resource,
								MAX(sp2.waittime) AS wait_time,
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0) AS blocked,
								MAX
								(
									CASE
										WHEN blk.session_id = sp2.spid THEN
											''blocker''
										ELSE
											RTRIM(sp2.hostprocess)
									END
								) AS hostprocess,
								CONVERT
								(
									BIT,
									MAX
									(
										CASE
											WHEN sp2.hostprocess > '''' THEN
												1
											ELSE
												0
										END
									)
								) AS is_user_process
							FROM
							(
								SELECT TOP(@i)
									session_id,
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								FROM @blockers

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, 0),
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								WHERE
									@blocker = 0

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, spid),
									queue_id,
									database_id
								FROM sys.dm_broker_activated_tasks
								WHERE
									@blocker = 0
							) AS blk
							INNER JOIN sys.sysprocesses AS sp2 ON
								sp2.spid = blk.session_id
								OR
								(
									blk.session_id = 0
									AND @blocker = 0
								)
							' +
							CASE 
								WHEN 
								(
									@get_task_info = 0 
									AND @find_block_leaders = 0
								) THEN
									'WHERE
										sp2.ecid = 0 
									' 
								ELSE
									''
							END +
							'GROUP BY
								sp2.spid,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END,
								RTRIM(sp2.lastwaittype),
								RTRIM(sp2.waitresource),
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0)
						) AS sp1
					) AS sp0
					WHERE
						@blocker = 1
						OR
						(1=1 
						' +
							--inclusive filter
							CASE
								WHEN @filter <> '' THEN
									CASE @filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @filter) <> 0 THEN
													'AND sp0.session_id = CONVERT(SMALLINT, @filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name LIKE @filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name LIKE @filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name LIKE @filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) LIKE @filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							--exclusive filter
							CASE
								WHEN @not_filter <> '' THEN
									CASE @not_filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @not_filter) <> 0 THEN
													'AND sp0.session_id <> CONVERT(SMALLINT, @not_filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name NOT LIKE @not_filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name NOT LIKE @not_filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name NOT LIKE @not_filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) NOT LIKE @not_filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							CASE @show_own_spid
								WHEN 1 THEN
									''
								ELSE
									'AND sp0.session_id <> @@spid 
									'
							END +
							CASE 
								WHEN @show_system_spids = 0 THEN
									'AND sp0.hostprocess > '''' 
									' 
								ELSE
									''
							END +
							CASE @show_sleeping_spids
								WHEN 0 THEN
									'AND sp0.status <> ''sleeping'' 
									'
								WHEN 1 THEN
									'AND
									(
										sp0.status <> ''sleeping''
										OR sp0.open_tran_count > 0
									)
									'
								ELSE
									''
							END +
						')
				) AS spx
			) AS spy
			WHERE
				spy.r = 1; 
			' + 
			CASE @recursion
				WHEN 1 THEN 
					'IF @@ROWCOUNT > 0
					BEGIN;
						INSERT @blockers
						(
							session_id
						)
						SELECT TOP(@i)
							blocked
						FROM @sessions
						WHERE
							NULLIF(blocked, 0) IS NOT NULL

						EXCEPT

						SELECT TOP(@i)
							session_id
						FROM @sessions; 
						' +

						CASE
							WHEN
							(
								@get_task_info > 0
								OR @find_block_leaders = 1
							) THEN
								'IF @@ROWCOUNT > 0
								BEGIN;
									SET @blocker = 1;
									GOTO BLOCKERS;
								END; 
								'
							ELSE 
								''
						END +
					'END; 
					'
				ELSE 
					''
			END +
			'SELECT TOP(@i)
				@recursion AS recursion,
				x.session_id,
				x.request_id,
				DENSE_RANK() OVER
				(
					ORDER BY
						x.session_id
				) AS session_number,
				' +
				CASE
					WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 
						'x.elapsed_time '
					ELSE 
						'0 '
				END + 
					'AS elapsed_time, 
					' +
				CASE
					WHEN
						(
							@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
							@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.avg_elapsed_time / 1000 '
					ELSE 
						'NULL '
				END + 
					'AS avg_elapsed_time, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_io '
					ELSE 
						'NULL '
				END + 
					'AS physical_io, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
							THEN 
								'x.reads '
					ELSE 
						'0 '
				END + 
					'AS reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_reads '
					ELSE 
						'0 '
				END + 
					'AS physical_reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
							THEN 
								'x.writes '
					ELSE 
						'0 '
				END + 
					'AS writes, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_allocations|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_allocations_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_allocations '
					ELSE 
						'0 '
				END + 
					'AS tempdb_allocations, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_current '
					ELSE 
						'0 '
				END + 
					'AS tempdb_current, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
							THEN
								'x.CPU '
					ELSE
						'0 '
				END + 
					'AS CPU, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
						AND @get_task_info = 2
							THEN 
								'x.thread_CPU_snapshot '
					ELSE 
						'0 '
				END + 
					'AS thread_CPU_snapshot, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
							THEN 
								'x.context_switches '
					ELSE 
						'NULL '
				END + 
					'AS context_switches, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
							THEN 
								'x.used_memory '
					ELSE 
						'0 '
				END + 
					'AS used_memory, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.tasks '
					ELSE 
						'NULL '
				END + 
					'AS tasks, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.status '
					ELSE 
						''''' '
				END + 
					'AS status, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								CASE @get_task_info
									WHEN 2 THEN
										'COALESCE(x.task_wait_info, x.sys_wait_info) '
									ELSE
										'x.sys_wait_info '
								END
					ELSE 
						'NULL '
				END + 
					'AS wait_info, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.transaction_id '
					ELSE 
						'NULL '
				END + 
					'AS transaction_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.open_tran_count '
					ELSE 
						'NULL '
				END + 
					'AS open_tran_count, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.sql_handle '
					ELSE 
						'NULL '
				END + 
					'AS sql_handle, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_start_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_start_offset, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_end_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_end_offset, 
					' +
				'NULL AS sql_text, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.plan_handle '
					ELSE 
						'NULL '
				END + 
					'AS plan_handle, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'NULLIF(x.blocking_session_id, 0) '
					ELSE 
						'NULL '
				END + 
					'AS blocking_session_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.percent_complete '
					ELSE 
						'NULL '
				END + 
					'AS percent_complete, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.host_name '
					ELSE 
						''''' '
				END + 
					'AS host_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.login_name '
					ELSE 
						''''' '
				END + 
					'AS login_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'DB_NAME(x.database_id) '
					ELSE 
						'NULL '
				END + 
					'AS database_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.program_name '
					ELSE 
						''''' '
				END + 
					'AS program_name, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'(
									SELECT TOP(@i)
										x.text_size,
										x.language,
										x.date_format,
										x.date_first,
										CASE x.quoted_identifier
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS quoted_identifier,
										CASE x.arithabort
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS arithabort,
										CASE x.ansi_null_dflt_on
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_null_dflt_on,
										CASE x.ansi_defaults
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_defaults,
										CASE x.ansi_warnings
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_warnings,
										CASE x.ansi_padding
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_padding,
										CASE ansi_nulls
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_nulls,
										CASE x.concat_null_yields_null
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS concat_null_yields_null,
										CASE x.transaction_isolation_level
											WHEN 0 THEN ''Unspecified''
											WHEN 1 THEN ''ReadUncomitted''
											WHEN 2 THEN ''ReadCommitted''
											WHEN 3 THEN ''Repeatable''
											WHEN 4 THEN ''Serializable''
											WHEN 5 THEN ''Snapshot''
										END AS transaction_isolation_level,
										x.lock_timeout,
										x.deadlock_priority,
										x.row_count,
										x.command_type, 
										' +
										CASE
											WHEN @output_column_list LIKE '%|[program_name|]%' ESCAPE '|' THEN
												'(
													SELECT TOP(1)
														CONVERT(uniqueidentifier, CONVERT(XML, '''').value(''xs:hexBinary( substring(sql:column("agent_info.job_id_string"), 0) )'', ''binary(16)'')) AS job_id,
														agent_info.step_id,
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''job_name''),
																TYPE
														),
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''step_name''),
																TYPE
														)
													FROM
													(
														SELECT TOP(1)
															SUBSTRING(x.program_name, CHARINDEX(''0x'', x.program_name) + 2, 32) AS job_id_string,
															SUBSTRING(x.program_name, CHARINDEX('': Step '', x.program_name) + 7, CHARINDEX('')'', x.program_name, CHARINDEX('': Step '', x.program_name)) - (CHARINDEX('': Step '', x.program_name) + 7)) AS step_id
														WHERE
															x.program_name LIKE N''SQLAgent - TSQL JobStep (Job 0x%''
													) AS agent_info
													FOR XML
														PATH(''agent_job_info''),
														TYPE
												),
												'
											ELSE ''
										END +
										CASE
											WHEN @get_task_info = 2 THEN
												'CONVERT(XML, x.block_info) AS block_info, 
												'
											ELSE
												''
										END +
										'x.host_process_id 
									FOR XML
										PATH(''additional_info''),
										TYPE
								) '
					ELSE
						'NULL '
				END + 
					'AS additional_info, 
				x.start_time, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[login_time|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'x.login_time '
					ELSE 
						'NULL '
				END + 
					'AS login_time, 
				x.last_request_start_time
			FROM
			(
				SELECT TOP(@i)
					y.*,
					CASE
						WHEN DATEDIFF(day, y.start_time, GETDATE()) > 24 THEN
							DATEDIFF(second, GETDATE(), y.start_time)
						ELSE DATEDIFF(ms, y.start_time, GETDATE())
					END AS elapsed_time,
					COALESCE(tempdb_info.tempdb_allocations, 0) AS tempdb_allocations,
					COALESCE
					(
						CASE
							WHEN tempdb_info.tempdb_current < 0 THEN 0
							ELSE tempdb_info.tempdb_current
						END,
						0
					) AS tempdb_current, 
					' +
					CASE
						WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1
							) THEN
								'N''('' + CONVERT(NVARCHAR, y.wait_duration_ms) + N''ms)'' +
									y.wait_type +
										CASE
											WHEN y.wait_type LIKE N''PAGE%LATCH_%'' THEN
												N'':'' +
												COALESCE(DB_NAME(CONVERT(INT, LEFT(y.resource_description, CHARINDEX(N'':'', y.resource_description) - 1))), N''(null)'') +
												N'':'' +
												SUBSTRING(y.resource_description, CHARINDEX(N'':'', y.resource_description) + 1, LEN(y.resource_description) - CHARINDEX(N'':'', REVERSE(y.resource_description)) - CHARINDEX(N'':'', y.resource_description)) +
												N''('' +
													CASE
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 1 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 8088 = 0
																THEN 
																	N''PFS''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 2 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511232 = 0
																THEN 
																	N''GAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 3 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511233 = 0
																THEN
																	N''SGAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 6 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511238 = 0 
																THEN 
																	N''DCM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 7 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511239 = 0 
																THEN 
																	N''BCM''
														ELSE 
															N''*''
													END +
												N'')''
											WHEN y.wait_type = N''CXPACKET'' THEN
												N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''nodeId'', y.resource_description) + 7, 4)
											WHEN y.wait_type LIKE N''LATCH[_]%'' THEN
												N'' ['' + LEFT(y.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', y.resource_description), 0), LEN(y.resource_description) + 1) - 1) + N'']''
											WHEN
												y.wait_type = N''OLEDB''
												AND y.resource_description LIKE N''%(SPID=%)'' THEN
													N''['' + LEFT(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) - 2) +
														N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) + 6, CHARINDEX(N'')'', y.resource_description, (CHARINDEX(N''(SPID='', y.resource_description) + 6)) - (CHARINDEX(N''(SPID='', y.resource_description) 
+ 6)) + '']''
											ELSE
												N''''
										END COLLATE Latin1_General_Bin2 AS sys_wait_info, 
										'
							ELSE
								''
						END +
						CASE
							WHEN @get_task_info = 2 THEN
								'tasks.physical_io,
								tasks.context_switches,
								tasks.tasks,
								tasks.block_info,
								tasks.wait_info AS task_wait_info,
								tasks.thread_CPU_snapshot,
								'
							ELSE
								'' 
					END +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN
							'CONVERT(INT, NULL) '
						ELSE 
							'qs.total_elapsed_time / qs.execution_count '
					END + 
						'AS avg_elapsed_time 
				FROM
				(
					SELECT TOP(@i)
						sp.session_id,
						sp.request_id,
						COALESCE(r.logical_reads, s.logical_reads) AS reads,
						COALESCE(r.reads, s.reads) AS physical_reads,
						COALESCE(r.writes, s.writes) AS writes,
						COALESCE(r.CPU_time, s.CPU_time) AS CPU,
						sp.memory_usage + COALESCE(r.granted_query_memory, 0) AS used_memory,
						LOWER(sp.status) AS status,
						COALESCE(r.sql_handle, sp.sql_handle) AS sql_handle,
						COALESCE(r.statement_start_offset, sp.statement_start_offset) AS statement_start_offset,
						COALESCE(r.statement_end_offset, sp.statement_end_offset) AS statement_end_offset,
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1 
							) THEN
								'sp.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
								sp.wait_resource COLLATE Latin1_General_Bin2 AS resource_description,
								sp.wait_time AS wait_duration_ms, 
								'
							ELSE
								''
						END +
						'NULLIF(sp.blocked, 0) AS blocking_session_id,
						r.plan_handle,
						NULLIF(r.percent_complete, 0) AS percent_complete,
						sp.host_name,
						sp.login_name,
						sp.program_name,
						s.host_process_id,
						COALESCE(r.text_size, s.text_size) AS text_size,
						COALESCE(r.language, s.language) AS language,
						COALESCE(r.date_format, s.date_format) AS date_format,
						COALESCE(r.date_first, s.date_first) AS date_first,
						COALESCE(r.quoted_identifier, s.quoted_identifier) AS quoted_identifier,
						COALESCE(r.arithabort, s.arithabort) AS arithabort,
						COALESCE(r.ansi_null_dflt_on, s.ansi_null_dflt_on) AS ansi_null_dflt_on,
						COALESCE(r.ansi_defaults, s.ansi_defaults) AS ansi_defaults,
						COALESCE(r.ansi_warnings, s.ansi_warnings) AS ansi_warnings,
						COALESCE(r.ansi_padding, s.ansi_padding) AS ansi_padding,
						COALESCE(r.ansi_nulls, s.ansi_nulls) AS ansi_nulls,
						COALESCE(r.concat_null_yields_null, s.concat_null_yields_null) AS concat_null_yields_null,
						COALESCE(r.transaction_isolation_level, s.transaction_isolation_level) AS transaction_isolation_level,
						COALESCE(r.lock_timeout, s.lock_timeout) AS lock_timeout,
						COALESCE(r.deadlock_priority, s.deadlock_priority) AS deadlock_priority,
						COALESCE(r.row_count, s.row_count) AS row_count,
						COALESCE(r.command, sp.cmd) AS command_type,
						COALESCE
						(
							CASE
								WHEN
								(
									s.is_user_process = 0
									AND r.total_elapsed_time >= 0
								) THEN
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									)
							END,
							NULLIF(COALESCE(r.start_time, sp.last_request_end_time), CONVERT(DATETIME, ''19000101'', 112)),
							(
								SELECT TOP(1)
									DATEADD(second, -(ms_ticks / 1000), GETDATE())
								FROM sys.dm_os_sys_info
							)
						) AS start_time,
						sp.login_time,
						CASE
							WHEN s.is_user_process = 1 THEN
								s.last_request_start_time
							ELSE
								COALESCE
								(
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									),
									s.last_request_start_time
								)
						END AS last_request_start_time,
						r.transaction_id,
						sp.database_id,
						sp.open_tran_count
					FROM @sessions AS sp
					LEFT OUTER LOOP JOIN sys.dm_exec_sessions AS s ON
						s.session_id = sp.session_id
						AND s.login_time = sp.login_time
					LEFT OUTER LOOP JOIN sys.dm_exec_requests AS r ON
						sp.status <> ''sleeping''
						AND r.session_id = sp.session_id
						AND r.request_id = sp.request_id
						AND
						(
							(
								s.is_user_process = 0
								AND sp.is_user_process = 0
							)
							OR
							(
								r.start_time = s.last_request_start_time
								AND s.last_request_end_time = sp.last_request_end_time
							)
						)
				) AS y
				' + 
				CASE 
					WHEN @get_task_info = 2 THEN
						CONVERT(VARCHAR(MAX), '') +
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								task_nodes.task_node.value(''(session_id/text())[1]'', ''SMALLINT'') AS session_id,
								task_nodes.task_node.value(''(request_id/text())[1]'', ''INT'') AS request_id,
								task_nodes.task_node.value(''(physical_io/text())[1]'', ''BIGINT'') AS physical_io,
								task_nodes.task_node.value(''(context_switches/text())[1]'', ''BIGINT'') AS context_switches,
								task_nodes.task_node.value(''(tasks/text())[1]'', ''INT'') AS tasks,
								task_nodes.task_node.value(''(block_info/text())[1]'', ''NVARCHAR(4000)'') AS block_info,
								task_nodes.task_node.value(''(waits/text())[1]'', ''NVARCHAR(4000)'') AS wait_info,
								task_nodes.task_node.value(''(thread_CPU_snapshot/text())[1]'', ''BIGINT'') AS thread_CPU_snapshot
							FROM
							(
								SELECT TOP(@i)
									CONVERT
									(
										XML,
										REPLACE
										(
											CONVERT(NVARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2,
											N''</waits></tasks><tasks><waits>'',
											N'', ''
										)
									) AS task_xml
								FROM
								(
									SELECT TOP(@i)
										CASE waits.r
											WHEN 1 THEN
												waits.session_id
											ELSE
												NULL
										END AS [session_id],
										CASE waits.r
											WHEN 1 THEN
												waits.request_id
											ELSE
												NULL
										END AS [request_id],											
										CASE waits.r
											WHEN 1 THEN
												waits.physical_io
											ELSE
												NULL
										END AS [physical_io],
										CASE waits.r
											WHEN 1 THEN
												waits.context_switches
											ELSE
												NULL
										END AS [context_switches],
										CASE waits.r
											WHEN 1 THEN
												waits.thread_CPU_snapshot
											ELSE
												NULL
										END AS [thread_CPU_snapshot],
										CASE waits.r
											WHEN 1 THEN
												waits.tasks
											ELSE
												NULL
										END AS [tasks],
										CASE waits.r
											WHEN 1 THEN
												waits.block_info
											ELSE
												NULL
										END AS [block_info],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													NVARCHAR(MAX),
													N''('' +
														CONVERT(NVARCHAR, num_waits) + N''x: '' +
														CASE num_waits
															WHEN 1 THEN
																CONVERT(NVARCHAR, min_wait_time) + N''ms''
															WHEN 2 THEN
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
															ELSE
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, avg_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE 
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
														END +
													N'')'' + wait_type COLLATE Latin1_General_Bin2
												),
												NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
												NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
												NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
											NCHAR(0),
											N''''
										) AS [waits]
									FROM
									(
										SELECT TOP(@i)
											w1.*,
											ROW_NUMBER() OVER
											(
												PARTITION BY
													w1.session_id,
													w1.request_id
												ORDER BY
													w1.block_info DESC,
													w1.num_waits DESC,
													w1.wait_type
											) AS r
										FROM
										(
											SELECT TOP(@i)
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks AS tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END AS wait_type,
												NULLIF(COUNT(COALESCE(task_info.runnable_time, wt2.waiting_task_address)), 0) AS num_waits,
												MIN(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS min_wait_time,
												AVG(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS avg_wait_time,
												MAX(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS max_wait_time,
												MAX(wt2.block_info) AS block_info
											FROM
											(
												SELECT TOP(@i)
													t.session_id,
													t.request_id,
													SUM(CONVERT(BIGINT, t.pending_io_count)) OVER (PARTITION BY t.session_id, t.request_id) AS physical_io,
													SUM(CONVERT(BIGINT, t.context_switches_count)) OVER (PARTITION BY t.session_id, t.request_id) AS context_switches, 
													' +
													CASE
														WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
															THEN
																'SUM(tr.usermode_time + tr.kernel_time) OVER (PARTITION BY t.session_id, t.request_id) '
														ELSE
															'CONVERT(BIGINT, NULL) '
													END + 
														' AS thread_CPU_snapshot, 
													COUNT(*) OVER (PARTITION BY t.session_id, t.request_id) AS num_tasks,
													t.task_address,
													t.task_state,
													CASE
														WHEN
															t.task_state = ''RUNNABLE''
															AND w.runnable_time > 0 THEN
																w.runnable_time
														ELSE
															NULL
													END AS runnable_time
												FROM sys.dm_os_tasks AS t
												CROSS APPLY
												(
													SELECT TOP(1)
														sp2.session_id
													FROM @sessions AS sp2
													WHERE
														sp2.session_id = t.session_id
														AND sp2.request_id = t.request_id
														AND sp2.status <> ''sleeping''
												) AS sp20
												LEFT OUTER HASH JOIN
												(
													SELECT TOP(@i)
														(
															SELECT TOP(@i)
																ms_ticks
															FROM sys.dm_os_sys_info
														) -
															w0.wait_resumed_ms_ticks AS runnable_time,
														w0.worker_address,
														w0.thread_address,
														w0.task_bound_ms_ticks
													FROM sys.dm_os_workers AS w0
													WHERE
														w0.state = ''RUNNABLE''
														OR @first_collection_ms_ticks >= w0.task_bound_ms_ticks
												) AS w ON
													w.worker_address = t.worker_address 
												' +
												CASE
													WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
														THEN
															'LEFT OUTER HASH JOIN sys.dm_os_threads AS tr ON
																tr.thread_address = w.thread_address
																AND @first_collection_ms_ticks >= w.task_bound_ms_ticks
															'
													ELSE
														''
												END +
											') AS task_info
											LEFT OUTER HASH JOIN
											(
												SELECT TOP(@i)
													wt1.wait_type,
													wt1.waiting_task_address,
													MAX(wt1.wait_duration_ms) AS wait_duration_ms,
													MAX(wt1.block_info) AS block_info
												FROM
												(
													SELECT DISTINCT TOP(@i)
														wt.wait_type +
															CASE
																WHEN wt.wait_type LIKE N''PAGE%LATCH_%'' THEN
																	'':'' +
																	COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) - 1))), N''(null)'') +
																	N'':'' +
																	SUBSTRING(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX(N'':'', REVERSE(wt.resource_description)) - CHARINDEX(N'':'', wt.resource_description)) +
																	N''('' +
																		CASE
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 1 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0
																					THEN 
																						N''PFS''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 2 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 
																					THEN 
																						N''GAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 3 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511233 = 0 
																					THEN 
																						N''SGAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 6 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511238 = 0 
																					THEN 
																						N''DCM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 7 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511239 = 0
																					THEN 
																						N''BCM''
																			ELSE
																				N''*''
																		END +
																	N'')''
																WHEN wt.wait_type = N''CXPACKET'' THEN
																	N'':'' + SUBSTRING(wt.resource_description, CHARINDEX(N''nodeId'', wt.resource_description) + 7, 4)
																WHEN wt.wait_type LIKE N''LATCH[_]%'' THEN
																	N'' ['' + LEFT(wt.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 1) + N'']''
																ELSE 
																	N''''
															END COLLATE Latin1_General_Bin2 AS wait_type,
														CASE
															WHEN
															(
																wt.blocking_session_id IS NOT NULL
																AND wt.wait_type LIKE N''LCK[_]%''
															) THEN
																(
																	SELECT TOP(@i)
																		x.lock_type,
																		REPLACE
																		(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																				DB_NAME
																				(
																					CONVERT
																					(
																						INT,
																						SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''dbid='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''dbid='', wt.resource_description) + 5), 0), LEN(wt.resource_de
scription) + 1) - CHARINDEX(N''dbid='', wt.resource_description) - 5)
																					)
																				),
																				NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
																				NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
																				NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
																			NCHAR(0),
																			N''''
																		) AS database_name,
																		CASE x.lock_type
																			WHEN N''objectlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''objid='', wt.resource_description), 0) + 6, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''objid='', wt.resource_description) + 6), 0), LEN(wt.resource_des
cription) + 1) - CHARINDEX(N''objid='', wt.resource_description) - 6)
																			ELSE
																				NULL
																		END AS object_id,
																		CASE x.lock_type
																			WHEN N''filelock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''fileid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''fileid='', wt.resource_description) + 7), 0), LEN(wt.resource_d
escription) + 1) - CHARINDEX(N''fileid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS file_id,
																		CASE
																			WHEN x.lock_type in (N''pagelock'', N''extentlock'', N''ridlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''associatedObjectId='', wt.resource_description), 0) + 19, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''associatedObjectId='', wt.resource_description) + 
19), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''associatedObjectId='', wt.resource_description) - 19)
																			WHEN x.lock_type in (N''keylock'', N''hobtlock'', N''allocunitlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hobtid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hobtid='', wt.resource_description) + 7), 0), LEN(wt.resource_d
escription) + 1) - CHARINDEX(N''hobtid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS hobt_id,
																		CASE x.lock_type
																			WHEN N''applicationlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hash='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hash='', wt.resource_description) + 5), 0), LEN(wt.resource_descr
iption) + 1) - CHARINDEX(N''hash='', wt.resource_description) - 5)
																			ELSE
																				NULL
																		END AS applock_hash,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''subresource='', wt.resource_description), 0) + 12, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''subresource='', wt.resource_description) + 12), 0), LEN(w
t.resource_description) + 1) - CHARINDEX(N''subresource='', wt.resource_description) - 12)
																			ELSE
																				NULL
																		END AS metadata_resource,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''classid='', wt.resource_description), 0) + 8, COALESCE(NULLIF(CHARINDEX(N'' dbid='', wt.resource_description) - CHARINDEX(N''classid='', wt.resource_description), 0), LEN(wt.resour
ce_description) + 1) - 8)
																			ELSE
																				NULL
																		END AS metadata_class_id
																	FROM
																	(
																		SELECT TOP(1)
																			LEFT(wt.resource_description, CHARINDEX(N'' '', wt.resource_description) - 1) COLLATE Latin1_General_Bin2 AS lock_type
																	) AS x
																	FOR XML
																		PATH('''')
																)
															ELSE NULL
														END AS block_info,
														wt.wait_duration_ms,
														wt.waiting_task_address
													FROM
													(
														SELECT TOP(@i)
															wt0.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
															wt0.resource_description COLLATE Latin1_General_Bin2 AS resource_description,
															wt0.wait_duration_ms,
															wt0.waiting_task_address,
															CASE
																WHEN wt0.blocking_session_id = p.blocked THEN
																	wt0.blocking_session_id
																ELSE
																	NULL
															END AS blocking_session_id
														FROM sys.dm_os_waiting_tasks AS wt0
														CROSS APPLY
														(
															SELECT TOP(1)
																s0.blocked
															FROM @sessions AS s0
															WHERE
																s0.session_id = wt0.session_id
																AND COALESCE(s0.wait_type, N'''') <> N''OLEDB''
																AND wt0.wait_type <> N''OLEDB''
														) AS p
													) AS wt
												) AS wt1
												GROUP BY
													wt1.wait_type,
													wt1.waiting_task_address
											) AS wt2 ON
												wt2.waiting_task_address = task_info.task_address
												AND wt2.wait_duration_ms > 0
												AND task_info.runnable_time IS NULL
											GROUP BY
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END
										) AS w1
									) AS waits
									ORDER BY
										waits.session_id,
										waits.request_id,
										waits.r
									FOR XML
										PATH(N''tasks''),
										TYPE
								) AS tasks_raw (task_xml_raw)
							) AS tasks_final
							CROSS APPLY tasks_final.task_xml.nodes(N''/tasks'') AS task_nodes (task_node)
							WHERE
								task_nodes.task_node.exist(N''session_id'') = 1
						) AS tasks ON
							tasks.session_id = y.session_id
							AND tasks.request_id = y.request_id 
						'
					ELSE
						''
				END +
				'LEFT OUTER HASH JOIN
				(
					SELECT TOP(@i)
						t_info.session_id,
						COALESCE(t_info.request_id, -1) AS request_id,
						SUM(t_info.tempdb_allocations) AS tempdb_allocations,
						SUM(t_info.tempdb_current) AS tempdb_current
					FROM
					(
						SELECT TOP(@i)
							tsu.session_id,
							tsu.request_id,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count AS tempdb_allocations,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count -
								tsu.user_objects_dealloc_page_count -
								tsu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_task_space_usage AS tsu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = tsu.session_id
						) AS p

						UNION ALL

						SELECT TOP(@i)
							ssu.session_id,
							NULL AS request_id,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count AS tempdb_allocations,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count -
								ssu.user_objects_dealloc_page_count -
								ssu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_session_space_usage AS ssu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = ssu.session_id
						) AS p
					) AS t_info
					GROUP BY
						t_info.session_id,
						COALESCE(t_info.request_id, -1)
				) AS tempdb_info ON
					tempdb_info.session_id = y.session_id
					AND tempdb_info.request_id =
						CASE
							WHEN y.status = N''sleeping'' THEN
								-1
							ELSE
								y.request_id
						END
				' +
				CASE 
					WHEN 
						NOT 
						(
							@get_avg_time = 1 
							AND @recursion = 1
						) THEN 
							''
					ELSE
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								*
							FROM sys.dm_exec_query_stats
						) AS qs ON
							qs.sql_handle = y.sql_handle
							AND qs.plan_handle = y.plan_handle
							AND qs.statement_start_offset = y.statement_start_offset
							AND qs.statement_end_offset = y.statement_end_offset
						'
				END + 
			') AS x
			OPTION (KEEPFIXED PLAN, OPTIMIZE FOR (@i = 1)); ';

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		SET @last_collection_start = GETDATE();

		IF @recursion = -1
		BEGIN;
			SELECT
				@first_collection_ms_ticks = ms_ticks
			FROM sys.dm_os_sys_info;
		END;

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_allocations,
			tempdb_current,
			CPU,
			thread_CPU_snapshot,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			transaction_id,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			additional_info,
			start_time,
			login_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter sysname, @not_filter sysname, @first_collection_ms_ticks BIGINT',
			@recursion, @filter, @not_filter, @first_collection_ms_ticks;

		--Collect transaction information?
		IF
			@recursion = 1
			AND
			(
				@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|'
				OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
			)
		BEGIN;	
			DECLARE @i INT;
			SET @i = 2147483647;

			UPDATE s
			SET
				tran_start_time =
					CONVERT
					(
						DATETIME,
						LEFT
						(
							x.trans_info,
							NULLIF(CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info) - 1, -1)
						),
						121
					),
				tran_log_writes =
					RIGHT
					(
						x.trans_info,
						LEN(x.trans_info) - CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info)
					)
			FROM
			(
				SELECT TOP(@i)
					trans_nodes.trans_node.value('(session_id/text())[1]', 'SMALLINT') AS session_id,
					COALESCE(trans_nodes.trans_node.value('(request_id/text())[1]', 'INT'), 0) AS request_id,
					trans_nodes.trans_node.value('(trans_info/text())[1]', 'NVARCHAR(4000)') AS trans_info				
				FROM
				(
					SELECT TOP(@i)
						CONVERT
						(
							XML,
							REPLACE
							(
								CONVERT(NVARCHAR(MAX), trans_raw.trans_xml_raw) COLLATE Latin1_General_Bin2, 
								N'</trans_info></trans><trans><trans_info>', N''
							)
						)
					FROM
					(
						SELECT TOP(@i)
							CASE u_trans.r
								WHEN 1 THEN u_trans.session_id
								ELSE NULL
							END AS [session_id],
							CASE u_trans.r
								WHEN 1 THEN u_trans.request_id
								ELSE NULL
							END AS [request_id],
							CONVERT
							(
								NVARCHAR(MAX),
								CASE
									WHEN u_trans.database_id IS NOT NULL THEN
										CASE u_trans.r
											WHEN 1 THEN COALESCE(CONVERT(NVARCHAR, u_trans.transaction_start_time, 121) + NCHAR(254), N'')
											ELSE N''
										END + 
											REPLACE
											(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
													CONVERT(VARCHAR(128), COALESCE(DB_NAME(u_trans.database_id), N'(null)')),
													NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
													NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
													NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
												NCHAR(0),
												N'?'
											) +
											N': ' +
										CONVERT(NVARCHAR, u_trans.log_record_count) + N' (' + CONVERT(NVARCHAR, u_trans.log_kb_used) + N' kB)' +
										N','
									ELSE
										N'N/A,'
								END COLLATE Latin1_General_Bin2
							) AS [trans_info]
						FROM
						(
							SELECT TOP(@i)
								trans.*,
								ROW_NUMBER() OVER
								(
									PARTITION BY
										trans.session_id,
										trans.request_id
									ORDER BY
										trans.transaction_start_time DESC
								) AS r
							FROM
							(
								SELECT TOP(@i)
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id,
									COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count,
									COALESCE(SUM(s_tran.database_transaction_log_bytes_used), 0) / 1024 AS log_kb_used,
									MIN(s_tran.database_transaction_begin_time) AS transaction_start_time
								FROM
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_active_transactions
									WHERE
										transaction_begin_time <= @last_collection_start
								) AS a_tran
								INNER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_database_transactions
									WHERE
										database_id < 32767
								) AS s_tran ON
									s_tran.transaction_id = a_tran.transaction_id
								LEFT OUTER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_session_transactions
								) AS tst ON
									s_tran.transaction_id = tst.transaction_id
								CROSS APPLY
								(
									SELECT TOP(1)
										s3.session_id,
										s3.request_id
									FROM
									(
										SELECT TOP(1)
											s1.session_id,
											s1.request_id
										FROM #sessions AS s1
										WHERE
											s1.transaction_id = s_tran.transaction_id
											AND s1.recursion = 1
											
										UNION ALL
									
										SELECT TOP(1)
											s2.session_id,
											s2.request_id
										FROM #sessions AS s2
										WHERE
											s2.session_id = tst.session_id
											AND s2.recursion = 1
									) AS s3
									ORDER BY
										s3.request_id
								) AS session_tran_map
								GROUP BY
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id
							) AS trans
						) AS u_trans
						FOR XML
							PATH('trans'),
							TYPE
					) AS trans_raw (trans_xml_raw)
				) AS trans_final (trans_xml)
				CROSS APPLY trans_final.trans_xml.nodes('/trans') AS trans_nodes (trans_node)
			) AS x
			INNER HASH JOIN #sessions AS s ON
				s.session_id = x.session_id
				AND s.request_id = x.request_id
			OPTION (OPTIMIZE FOR (@i = 1));
		END;

		--Variables for text and plan collection
		DECLARE	
			@session_id SMALLINT,
			@request_id INT,
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT,
			@start_time DATETIME,
			@database_name sysname;

		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN;
			DECLARE sql_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					request_id,
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND sql_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@session_id,
				@request_id,
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										N'--' + NCHAR(13) + NCHAR(10) +
										CASE 
											WHEN @get_full_inner_text = 1 THEN est.text
											WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN est.text
											WHEN SUBSTRING(est.text, (@statement_start_offset/2), 2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
											ELSE
												CASE
													WHEN @statement_start_offset > 0 THEN
														SUBSTRING
														(
															est.text,
															((@statement_start_offset/2) + 1),
															(
																CASE
																	WHEN @statement_end_offset = -1 THEN 2147483647
																	ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																END
															)
														)
													ELSE RTRIM(LTRIM(est.text))
												END
										END +
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2,
										NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
										NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
										NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
									NCHAR(0),
									N''
								) AS [processing-instruction(query)]
							FOR XML
								PATH(''),
								TYPE
						),
						s.statement_start_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN 0
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN 0
								ELSE @statement_start_offset
							END,
						s.statement_end_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN -1
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN -1
								ELSE @statement_end_offset
							END
					FROM 
						#sessions AS s,
						(
							SELECT TOP(1)
								text
							FROM
							(
								SELECT 
									text, 
									0 AS row_num
								FROM sys.dm_exec_sql_text(@sql_handle)
								
								UNION ALL
								
								SELECT 
									NULL,
									1 AS row_num
							) AS est0
							ORDER BY
								row_num
						) AS est
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@session_id,
					@request_id,
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id SMALLINT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX),
									N'--' + NCHAR(13) + NCHAR(10) + br.EventInfo + NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.request_id = 0
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE plan_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					session_id,
					request_id,
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND plan_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@session_id,
				@request_id,
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT
								CONVERT(xml, query_plan)
							FROM sys.dm_exec_text_query_plan
							(
								@plan_handle, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_start_offset
									ELSE
										0
								END, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_end_offset
									ELSE
										-1
								END
							)
						)
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					IF ERROR_NUMBER() = 6335
					BEGIN;
						UPDATE s
						SET
							s.query_plan =
							(
								SELECT
									N'--' + NCHAR(13) + NCHAR(10) + 
									N'-- Could not render showplan due to XML data type limitations. ' + NCHAR(13) + NCHAR(10) + 
									N'-- To see the graphical plan save the XML below as a .SQLPLAN file and re-open in SSMS.' + NCHAR(13) + NCHAR(10) +
									N'--' + NCHAR(13) + NCHAR(10) +
										REPLACE(qp.query_plan, N'<RelOp', NCHAR(13)+NCHAR(10)+N'<RelOp') + 
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2 AS [processing-instruction(query_plan)]
								FROM sys.dm_exec_text_query_plan
								(
									@plan_handle, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_start_offset
										ELSE
											0
									END, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_end_offset
										ELSE
											-1
									END
								) AS qp
								FOR XML
									PATH(''),
									TYPE
							)
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
					ELSE
					BEGIN;
						UPDATE s
						SET
							s.query_plan = 
								CASE ERROR_NUMBER() 
									WHEN 1222 THEN '<timeout_exceeded />'
									ELSE '<error message="' + ERROR_MESSAGE() + '" />'
								END
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@session_id,
					@request_id,
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					database_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND database_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT FROM locks_cursor
			INTO 
				@database_name;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'index_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'i.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'principal_name = ' + 
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'dp.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.database_name = @database_name ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE 
						database_name = @database_name
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM locks_cursor
				INTO
					@database_name;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, database_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX), 
									l1.database_name COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [Database/@name],
						MIN(l1.query_error) AS [Database/@query_error],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.database_name = l1.database_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										l4.index_name AS [Lock/@index_name],
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END AS [Lock/@schema_name],
										l4.principal_name AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.database_name = l4.database_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML
										PATH(''),
										TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.database_name = l1.database_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.database_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = s.request_id
						AND l1.start_time IN (s.start_time, s.last_request_start_time)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.database_name
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;

		IF
			@get_task_info = 2
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			CREATE TABLE #blocked_requests
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				database_name sysname NOT NULL,
				object_id INT,
				hobt_id BIGINT,
				schema_id INT,
				schema_name sysname NULL,
				object_name sysname NULL,
				query_error NVARCHAR(2048),
				PRIMARY KEY (database_name, session_id, request_id)
			);

			CREATE STATISTICS s_database_name ON #blocked_requests (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #blocked_requests (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #blocked_requests (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_query_error ON #blocked_requests (query_error)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		
			INSERT #blocked_requests
			(
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				schema_id
			)
			SELECT
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				CONVERT(INT, SUBSTRING(schema_node, CHARINDEX(' = ', schema_node) + 3, LEN(schema_node))) AS schema_id
			FROM
			(
				SELECT
					session_id,
					request_id,
					agent_nodes.agent_node.value('(database_name/text())[1]', 'sysname') AS database_name,
					agent_nodes.agent_node.value('(object_id/text())[1]', 'int') AS object_id,
					agent_nodes.agent_node.value('(hobt_id/text())[1]', 'bigint') AS hobt_id,
					agent_nodes.agent_node.value('(metadata_resource/text()[.="SCHEMA"]/../../metadata_class_id/text())[1]', 'varchar(100)') AS schema_node
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//block_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			) AS t
			WHERE
				t.database_name IS NOT NULL
				AND
				(
					t.object_id IS NOT NULL
					OR t.hobt_id IS NOT NULL
					OR t.schema_node IS NOT NULL
				);
			
			DECLARE blocks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR
				SELECT DISTINCT
					database_name
				FROM #blocked_requests;
				
			OPEN blocks_cursor;
			
			FETCH NEXT FROM blocks_cursor
			INTO 
				@database_name;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = 
						CONVERT(NVARCHAR(MAX), '') +
						'UPDATE b ' +
						'SET ' +
							'b.schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'b.object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #blocked_requests AS b ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = b.hobt_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(p.object_id, b.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(o.schema_id, b.schema_id) ' +
						'WHERE ' +
							'b.database_name = @database_name; ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #blocked_requests
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE
						database_name = @database_name;
				END CATCH;

				FETCH NEXT FROM blocks_cursor
				INTO
					@database_name;
			END;
			
			CLOSE blocks_cursor;
			DEALLOCATE blocks_cursor;
			
			UPDATE s
			SET
				additional_info.modify
				('
					insert <schema_name>{sql:column("b.schema_name")}</schema_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.schema_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <object_name>{sql:column("b.object_name")}</object_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.object_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <query_error>{sql:column("b.query_error")}</query_error>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.query_error IS NOT NULL;
		END;

		IF
			@output_column_list LIKE '%|[program_name|]%' ESCAPE '|'
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			DECLARE @job_id UNIQUEIDENTIFIER;
			DECLARE @step_id INT;

			DECLARE agent_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					s.session_id,
					agent_nodes.agent_node.value('(job_id/text())[1]', 'uniqueidentifier') AS job_id,
					agent_nodes.agent_node.value('(step_id/text())[1]', 'int') AS step_id
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//agent_job_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			OPTION (KEEPFIXED PLAN);
			
			OPEN agent_cursor;

			FETCH NEXT FROM agent_cursor
			INTO 
				@session_id,
				@job_id,
				@step_id;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					DECLARE @job_name sysname;
					SET @job_name = NULL;
					DECLARE @step_name sysname;
					SET @step_name = NULL;
					
					SELECT
						@job_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									j.name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							),
						@step_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									s.step_name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							)
					FROM msdb.dbo.sysjobs AS j
					INNER JOIN msdb..sysjobsteps AS s ON
						j.job_id = s.job_id
					WHERE
						j.job_id = @job_id
						AND s.step_id = @step_id;

					IF @job_name IS NOT NULL
					BEGIN;
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@job_name")}
								into (/additional_info/agent_job_info/job_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
						
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@step_name")}
								into (/additional_info/agent_job_info/step_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
					END;
				END TRY
				BEGIN CATCH;
					DECLARE @msdb_error_message NVARCHAR(256);
					SET @msdb_error_message = ERROR_MESSAGE();
				
					UPDATE s
					SET
						additional_info.modify
						('
							insert <msdb_query_error>{sql:variable("@msdb_error_message")}</msdb_query_error>
							as last
							into (/additional_info/agent_job_info)[1]
						')
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM agent_cursor
				INTO 
					@session_id,
					@job_id,
					@step_id;
			END;

			CLOSE agent_cursor;
			DEALLOCATE agent_cursor;
		END; 
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE
						WHEN @format_output IN (1, 2) THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE 
						WHEN  @format_output IN (1, 2) THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_allocations
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_allocations, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					CASE
						WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
							--physical_io_delta			
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_io_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
											ELSE 'physical_io_delta '
										END +
								'ELSE NULL ' +
							'END AS physical_io_delta, ' +
							--reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											ELSE 'reads_delta '
										END +
								'ELSE NULL ' +
							'END AS reads_delta, ' +
							--physical_reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											ELSE 'physical_reads_delta '
										END + 
								'ELSE NULL ' +
							'END AS physical_reads_delta, ' +
							--writes_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND writes_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											ELSE 'writes_delta '
										END + 
								'ELSE NULL ' +
							'END AS writes_delta, ' +
							--tempdb_allocations_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND tempdb_allocations_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											ELSE 'tempdb_allocations_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_allocations_delta, ' +
							--tempdb_current_delta
							--this is the only one that can (legitimately) go negative 
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											ELSE 'tempdb_current_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_current_delta, ' +
							--CPU_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
											'CASE ' +
												'WHEN ' +
													'thread_CPU_delta > CPU_delta ' +
													'AND thread_CPU_delta > 0 ' +
														'THEN ' +
															CASE @format_output
																WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, thread_CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																ELSE 'thread_CPU_delta '
															END + 
												'WHEN CPU_delta >= 0 THEN ' +
													CASE @format_output
														WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														ELSE 'CPU_delta '
													END + 
												'ELSE NULL ' +
											'END ' +
								'ELSE ' +
									'NULL ' +
							'END AS CPU_delta, ' +
							--context_switches_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND context_switches_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											ELSE 'context_switches_delta '
										END + 
								'ELSE NULL ' +
							'END AS context_switches_delta, ' +
							--used_memory_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND used_memory_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											ELSE 'used_memory_delta '
										END + 
								'ELSE NULL ' +
							'END AS used_memory_delta, '
						ELSE ''
					END +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'additional_info, ' +
					'start_time, ' +
					'login_time, ' +
					'CASE ' +
						'WHEN status = N''sleeping'' THEN NULL ' +
						'ELSE request_id ' +
					'END AS request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'CASE ' +
							'MAX ' +
							'( ' +
								'LEN ' +
								'( ' +
									'CONVERT ' +
									'( ' +
										'VARCHAR, ' +
										'CASE ' +
											'WHEN elapsed_time < 0 THEN ' +
												'(-1 * elapsed_time) / 86400 ' +
											'ELSE ' +
												'elapsed_time / 86400000 ' +
										'END ' +
									') ' +
								') ' +
							') OVER () ' +
								'WHEN 1 THEN 2 ' +
								'ELSE ' +
									'MAX ' +
									'( ' +
										'LEN ' +
										'( ' +
											'CONVERT ' +
											'( ' +
												'VARCHAR, ' +
												'CASE ' +
													'WHEN elapsed_time < 0 THEN ' +
														'(-1 * elapsed_time) / 86400 ' +
													'ELSE ' +
														'elapsed_time / 86400000 ' +
												'END ' +
											') ' +
										') ' +
									') OVER () ' +
						'END AS max_elapsed_length, ' +
						CASE
							WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
								'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
								'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
								'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
								'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
								'MAX(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_allocations_delta, ' +
								'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
								'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
								'MAX(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) AS thread_CPU_delta, ' +
								'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
								'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
								'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, '
							ELSE ''
						END +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					CASE 
						WHEN @sort_order = '' THEN ''
						ELSE
							'ORDER BY ' +
								@sort_order
					END +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE ' +
											'WHEN DATA_TYPE LIKE ''%char'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML ' +
										'PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;


go

/**************************************************************************************************************  
SP    명 : dbo.up_DBA_ProcessKill_db
작성정보: 2012-07-25 김태환
내용	    : 활성 프로세서 ALL KILL
dbo.up_DBA_ProcessKill_db 'chglog'
**************************************************************************************************************/ 
CREATE  procedure   [dbo].[up_DBA_ProcessKill_db] 
@dbname sysname
as
	set nocount on 
	set ansi_warnings off

	declare @temp table (seqno int identity, kill_sql nvarchar(50))
	declare @kill_sql nvarchar(50)
	declare @max_seqno int, @seqno int

	insert into @temp(kill_sql)
	select 'kill ' + convert(varchar(10), spid) 
	from 
	(
		select distinct(spid) as spid
		  from master.dbo.sysprocesses with (nolock) 
		 where spid > 50 and db_name(dbid) = @dbname
	) a

	set @seqno = 0
	select @max_seqno = isnull(max(seqno), 0) from @temp 

	if @max_seqno = 0 return

	while (1=1)
	begin
				set @seqno = @seqno + 1
				select @kill_sql = kill_sql from @temp where seqno = @seqno
		
				execute sp_executesql  @kill_sql
		
				if @@error <> 0 continue;
					if @seqno >= @max_seqno break;
	end
go




/*==============================================================  
목적 : 데이터베이스서버의 로컬 트레이싱을 위해  
작성자 : 김준환  
작성일 : 2004.08.06.  
사용법 :  
 1. Duration > 1000ms이상인 쿼리를 E:\Trace\Trace.trc 파일을 Rollover로 100MB를 생성  
 EXEC dbo.up_StartTrace N'E:\Trace\Trace', 100, 1000  
==============================================================*/  
CREATE PROCEDURE [dbo].[up_StartTrace] (@TraceFileName NVARCHAR(245) = N'd:\Trace\Trace',  
    @MaxFileSize BIGINT = 200,  
	@HostName NVARCHAR(255) = NULL,  
    @Duration BIGINT = NULL,  
    @Reads BIGINT = NULL,  
    @CPU BIGINT = NULL,  
    @TextData NVARCHAR(245) = NULL,  
    @ApplicationName NVARCHAR(245) = NULL  
     )  
AS  
-- 반환값  
DECLARE @RC int  
-- 트레이스ID  
DECLARE @TraceID int  
-- 캡처 이벤트  
DECLARE @Events varchar(300)  
-- 해당 이벤트 켜기  
DECLARE @on BIT  
-- 캡처할 컬럼  
DECLARE @Cols varchar(300)  
  
-- 캡처 이벤트  
-- 10 : RPC:Completed  
-- 11 : RPC:Starting  
-- 12 : SQL:BatchCompleted  
-- 13 : SQL:BatchStarting  
-- 40 : SQL:StmtStarting
-- 41 : SQL:StmtCompleted
-- 44 : SP:StmtStarting
-- 45 : SP:StmtCompleted
--SET @Events = '10,11,12,13,40,41,44,45'
SET @Events = '10,12,41,45'
  
-- 모든 컬럼 캡처  
SET @Cols='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,'  
SET @Cols='1,3,4,8,9,10,11,12,13,14,15,16,18,22,31,34,35,50,'
  
-- 트레이스 생성  
-- 트레이스파일 TRACE_FILE_ROLLOVER  
EXEC @rc = dbo.sp_trace_create @TraceID output, 2, @TraceFileName, @MaxFileSize  
IF @rc <> 0 BEGIN  
 IF @rc = 10 RAISERROR ('잘못된 옵션사용',16,1)  
 ELSE IF @rc = 12 RAISERROR ('트레이스 파일을 생성하지 못하였습니다.',16,1)  
 ELSE RAISERROR ('알 수 없는 오류',16,1)  
END  
  
-- 트레이스ID전달  
SELECT TraceID = @TraceID  
  
-- 캡처이벤트 셋팅  
SELECT @on = 1  
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
   EXEC dbo.sp_trace_setevent @TraceId=@TraceID, @eventid=@Event, @columnid=@Col, @on=@On  
   SET @ColStr=SUBSTRING(@ColStr,@j+1,300)  
   SET @j=CHARINDEX(',',@ColStr)  
  END  
  SET @Events=SUBSTRING(@Events,@i+1,300)  
  SET @i=CHARINDEX(',',@Events)  
 END  
END  
  
-- HostName
IF @HostName IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 8, 0, 6 , @HostName

-- Duration >= @Duration  
IF @Duration IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 13, 0, 4 , @Duration  
  
-- Reads >= @Reads  
IF @Reads IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 16, 0, 4 , @Reads  
  
-- CPU >= @CPU  
IF @CPU IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 18, 0, 4 , @CPU  
  
-- SQL Profiler에의하여 생성되는 명령 제외  
EXEC dbo.sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler'  
  
-- TextData NOT LIKE 'SET TRANSACTION ISOLATION LEVEL READ COMMITTED'  
IF @TextData IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 1, 0, 7, 'SET TRANSACTION ISOLATION LEVEL READ COMMITTED'  
  
-- TextData LIKE @TextData  
IF @TextData IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 1, 0, 6, @TextData  
  
-- ApplicationName = @ApplicationName  
IF @ApplicationName IS NOT NULL  
 EXEC dbo.sp_trace_setfilter @TraceID, 10, 0, 0, @ApplicationName  
  
-- 트레이스 시작 (status 1 = start)  
EXEC @RC = sp_trace_setstatus @TraceID, 1  

RETURN @TraceID

go




/*==============================================================  
목적 : 데이터베이스서버의 로컬 트레이싱 중지  
작성자 : 김준환  
작성일 : 2004.08.06.  
사용법 : EXEC dbo.up_StopTrace  
주의사항: 1. Profiler에 의해 실행된 Trace까지 중지될 수 있음  
    2. 위와 같은 경우에는 서버 트레이스가 중지될 때 까지 다시 실행시켜야 함.  
==============================================================*/  
CREATE PROCEDURE [dbo].[up_StopTrace] (@TraceID INT = 2) 
AS  
/* 서버 트레이싱 중지 */  
  
 -- First stop the trace   
 EXEC dbo.sp_trace_setstatus @TraceID, 0  
  
 -- Close and then delete its definition from SQL Server   
 EXEC dbo.sp_trace_setstatus @TraceID, 2  
go
CREATE PROCEDURE [dbo].[sp_Blitz_dba]
	@SERVER_ID INT , 
    @CheckUserDatabaseObjects TINYINT = 1 ,
    @CheckProcedureCache TINYINT = 0 ,
    @OutputType VARCHAR(20) = 'TABLE' ,
    @OutputProcedureCache TINYINT = 0 ,
    @CheckProcedureCacheFilter VARCHAR(10) = NULL ,
    @CheckServerInfo TINYINT = 0 ,
    @SkipChecksServer NVARCHAR(256) = NULL ,
    @SkipChecksDatabase NVARCHAR(256) = NULL ,
    @SkipChecksSchema NVARCHAR(256) = NULL ,
    @SkipChecksTable NVARCHAR(256) = NULL ,
    @IgnorePrioritiesBelow INT = NULL ,
    @IgnorePrioritiesAbove INT = NULL ,
    @OutputDatabaseName NVARCHAR(128) = NULL ,
    @OutputSchemaName NVARCHAR(256) = NULL ,
    @OutputTableName NVARCHAR(256) = NULL ,
    @OutputXMLasNVARCHAR TINYINT = 0 ,
    @EmailRecipients VARCHAR(MAX) = NULL ,
    @EmailProfile sysname = NULL ,
    @SummaryMode TINYINT = 0 ,
    @Help TINYINT = 0 ,
    @Version INT = NULL OUTPUT,
    @VersionDate DATETIME = NULL OUTPUT
AS
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT @Version = 36, @VersionDate = '20141005'

	IF @Help = 1 PRINT '
	/*
	sp_Blitz (TM) v36 - October 5, 2014

	(C) 2014, Brent Ozar Unlimited.
	See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

	To learn more, visit http://www.BrentOzar.com/blitz where you can download
	new versions for free, watch training videos on how it works, get more info on
	the findings, and more.  To contribute code and see your name in the change
	log, email your improvements & checks to Help@BrentOzar.com.

	To request a feature or change: http://support.brentozar.com/
	To contribute code: http://www.brentozar.com/contributing-code/

	Known limitations of this version:
	 - No support for SQL Server 2000 or compatibility mode 80.
	 - If a database name has a question mark in it, some tests will fail. Gotta
	   love that unsupported sp_MSforeachdb.
	 - If you have offline databases, sp_Blitz fails the first time you run it,
	   but does work the second time. (Hoo, boy, this will be fun to debug.)

	Unknown limitations of this version:
	 - None.  (If we knew them, they would be known. Duh.)


 	Changes in v36 - October 5, 2014
	 - Added non-default database configuration checks looking at sys.databases
	   as checks 131-144. Catches things like delayed durability, forced params.
     - Added check for long file growths from the default trace, 151.
     - Added check for serious errors in the default trace, 150.
	 - Added Hekaton memory use and transaction error checks 145-147.
	 - Added checks for database files on network shares or Azure, 148-149.
	 - Added server name row in output when @CheckServerInfo = 1.
 	 - Moved contributions to support.brentozar.com.
	 - Check 78 for stored procs with RECOMPILE now ignores sp_Blitz%.
     - Removed redundant check 58 (collation, dupe of 76.)

	Changes in v35 - June 17, 2014
	 - John Hill fixed a bug in check 134 looking for deadlocks.
	 - Robert Virag improved check 19 looking for replication subscribers.
	 - Russell Hart improved check 34 to avoid blocking during restores.
	 - Added check 126 for priority boost enabled. It was always in the non-
	   default configurations check, but this one is so bad we called it out.
	 - Added checks 128 and 129 for unsupported builds of SQL Server.
	 - Added check 127 for unneccessary backups of ReportServerTempDB.
	 - Changed fill factor threshold to <80% to match sp_BlitzIndex.

	For prior changes, see: http://www.BrentOzar.com/blitz/changelog/


	Parameter explanations:

	@CheckUserDatabaseObjects	1=review user databases for triggers, heaps, etc. Takes more time for more databases and objects.
	@CheckServerInfo			1=show server info like CPUs, memory, virtualization
	@CheckProcedureCache		1=top 20-50 resource-intensive cache plans and analyze them for common performance issues.
	@OutputProcedureCache		1=output the top 20-50 resource-intensive plans even if they did not trigger an alarm
	@CheckProcedureCacheFilter	''CPU'' | ''Reads'' | ''Duration'' | ''ExecCount''
	@OutputType					''TABLE''=table | ''COUNT''=row with number found | ''SCHEMA''=version and field list
	@IgnorePrioritiesBelow		100=ignore priorities below 100
	@IgnorePrioritiesAbove		100=ignore priorities above 100
	For the rest of the parameters, see http://www.brentozar.com/blitz/documentation for details.


	*/'
	ELSE IF @OutputType = 'SCHEMA'
	BEGIN
		SELECT @Version AS Version,
		FieldList = '[Priority] TINYINT, [FindingsGroup] VARCHAR(50), [Finding] VARCHAR(200), [DatabaseName] NVARCHAR(128), [URL] VARCHAR(200), [Details] NVARCHAR(4000)
		, [QueryPlan] NVARCHAR(MAX), [QueryPlanFiltered] NVARCHAR(MAX), [CheckID] INT'

	END
	ELSE /* IF @OutputType = 'SCHEMA' */
	BEGIN

		/*
		We start by creating #BlitzResults. It's a temp table that will store all of
		the results from our checks. Throughout the rest of this stored procedure,
		we're running a series of checks looking for dangerous things inside the SQL
		Server. When we find a problem, we insert rows into #BlitzResults. At the
		end, we return these results to the end user.

		#BlitzResults has a CheckID field, but there's no Check table. As we do
		checks, we insert data into this table, and we manually put in the CheckID.
		We (Brent Ozar Unlimited) maintain a list of the checks by ID#. You can
		download that from http://www.BrentOzar.com/blitz/documentation/ - you'll
		see why it can help shortly.
		*/
		DECLARE @StringToExecute NVARCHAR(4000)
			,@curr_tracefilename NVARCHAR(500)
			,@base_tracefilename NVARCHAR(500)
			,@indx int
			,@query_result_separator CHAR(1)
			,@EmailSubject NVARCHAR(255)
			,@EmailBody NVARCHAR(MAX)
			,@EmailAttachmentFilename NVARCHAR(255)
			,@ProductVersion NVARCHAR(128)
			,@ProductVersionMajor DECIMAL(10,2)
			,@ProductVersionMinor DECIMAL(10,2)
			,@CurrentName NVARCHAR(128)
			,@CurrentDefaultValue NVARCHAR(200)
			,@CurrentCheckID INT
			,@CurrentPriority INT
			,@CurrentFinding VARCHAR(200)
			,@CurrentURL VARCHAR(200)
			,@CurrentDetails NVARCHAR(4000);

		IF OBJECT_ID('tempdb..#BlitzResults') IS NOT NULL
			DROP TABLE #BlitzResults;
		CREATE TABLE #BlitzResults
			(
			  ID INT IDENTITY(1, 1) ,
			  CheckID INT ,
			  DatabaseName NVARCHAR(128) ,
			  Priority TINYINT ,
			  FindingsGroup VARCHAR(50) ,
			  Finding VARCHAR(200) ,
			  URL VARCHAR(200) ,
			  ObjectName		nvarchar(128),
			  Details NVARCHAR(4000) ,
			  QueryPlan [XML] NULL ,
			  QueryPlanFiltered [NVARCHAR](MAX) NULL
			);

		/*
		You can build your own table with a list of checks to skip. For example, you
		might have some databases that you don't care about, or some checks you don't
		want to run. Then, when you run sp_Blitz, you can specify these parameters:
		@SkipChecksDatabase = 'DBAtools',
		@SkipChecksSchema = 'dbo',
		@SkipChecksTable = 'BlitzChecksToSkip'
		Pass in the database, schema, and table that contains the list of checks you
		want to skip. This part of the code checks those parameters, gets the list,
		and then saves those in a temp table. As we run each check, we'll see if we
		need to skip it.

		Really anal-retentive users will note that the @SkipChecksServer parameter is
		not used. YET. We added that parameter in so that we could avoid changing the
		stored proc's surface area (interface) later.
		*/
		IF OBJECT_ID('tempdb..#SkipChecks') IS NOT NULL
			DROP TABLE #SkipChecks;
		CREATE TABLE #SkipChecks
			(
			  DatabaseName NVARCHAR(128) ,
			  CheckID INT ,
			  ServerName NVARCHAR(128)
			);
		CREATE CLUSTERED INDEX IX_CheckID_DatabaseName ON #SkipChecks(CheckID, DatabaseName);

		IF @SkipChecksTable IS NOT NULL
			AND @SkipChecksSchema IS NOT NULL
			AND @SkipChecksDatabase IS NOT NULL
			BEGIN
				SET @StringToExecute = 'INSERT INTO #SkipChecks(DatabaseName, CheckID, ServerName )
				SELECT DISTINCT DatabaseName, CheckID, ServerName
				FROM ' + QUOTENAME(@SkipChecksDatabase) + '.' + QUOTENAME(@SkipChecksSchema) + '.' + QUOTENAME(@SkipChecksTable)
					+ ' WHERE ServerName IS NULL OR ServerName = SERVERPROPERTY(''ServerName'');'
				EXEC(@StringToExecute)
			END

		IF NOT EXISTS ( SELECT  1
							FROM    #SkipChecks
							WHERE   DatabaseName IS NULL AND CheckID = 106 )
							AND (select convert(int,value_in_use) from sys.configurations where name = 'default trace enabled' ) = 1
			BEGIN
					select @curr_tracefilename = [path] from sys.traces where is_default = 1 ;
					set @curr_tracefilename = reverse(@curr_tracefilename);
					select @indx = patindex('%\%', @curr_tracefilename) ;
					set @curr_tracefilename = reverse(@curr_tracefilename) ;
					set @base_tracefilename = left( @curr_tracefilename,len(@curr_tracefilename) - @indx) + '\log.trc' ;
			END


		/*
		That's the end of the SkipChecks stuff.
		The next several tables are used by various checks later.
		*/
		IF OBJECT_ID('tempdb..#ConfigurationDefaults') IS NOT NULL
			DROP TABLE #ConfigurationDefaults;
		CREATE TABLE #ConfigurationDefaults
			(
			  name NVARCHAR(128) ,
			  DefaultValue BIGINT,
			  CheckID INT
			);

		IF OBJECT_ID('tempdb..#DatabaseDefaults') IS NOT NULL
			DROP TABLE #DatabaseDefaults;
		CREATE TABLE #DatabaseDefaults
			(
				name NVARCHAR(128) ,
				DefaultValue NVARCHAR(200),
				CheckID INT,
		        Priority INT,
		        Finding VARCHAR(200),
		        URL VARCHAR(200),
		        Details NVARCHAR(4000)
			);



		IF OBJECT_ID('tempdb..#DBCCs') IS NOT NULL
			DROP TABLE #DBCCs;
		CREATE TABLE #DBCCs
			(
			  ID INT IDENTITY(1, 1)
					 PRIMARY KEY ,
			  ParentObject VARCHAR(255) ,
			  Object VARCHAR(255) ,
			  Field VARCHAR(255) ,
			  Value VARCHAR(255) ,
			  DbName NVARCHAR(128) NULL
			)


		IF OBJECT_ID('tempdb..#LogInfo2012') IS NOT NULL
			DROP TABLE #LogInfo2012;
		CREATE TABLE #LogInfo2012
			(
			  recoveryunitid INT ,
			  FileID SMALLINT ,
			  FileSize BIGINT ,
			  StartOffset BIGINT ,
			  FSeqNo BIGINT ,
			  [Status] TINYINT ,
			  Parity TINYINT ,
			  CreateLSN NUMERIC(38)
			);

		IF OBJECT_ID('tempdb..#LogInfo') IS NOT NULL
			DROP TABLE #LogInfo;
		CREATE TABLE #LogInfo
			(
			  FileID SMALLINT ,
			  FileSize BIGINT ,
			  StartOffset BIGINT ,
			  FSeqNo BIGINT ,
			  [Status] TINYINT ,
			  Parity TINYINT ,
			  CreateLSN NUMERIC(38)
			);

		IF OBJECT_ID('tempdb..#partdb') IS NOT NULL
			DROP TABLE #partdb;
		CREATE TABLE #partdb
			(
			  dbname NVARCHAR(128) ,
			  objectname NVARCHAR(200) ,
			  type_desc NVARCHAR(128)
			)

		IF OBJECT_ID('tempdb..#TraceStatus') IS NOT NULL
			DROP TABLE #TraceStatus;
		CREATE TABLE #TraceStatus
			(
			  TraceFlag VARCHAR(10) ,
			  status BIT ,
			  Global BIT ,
			  Session BIT
			);

		IF OBJECT_ID('tempdb..#driveInfo') IS NOT NULL
			DROP TABLE #driveInfo;
		CREATE TABLE #driveInfo
			(
			  drive NVARCHAR ,
			  SIZE DECIMAL(18, 2)
			)


		IF OBJECT_ID('tempdb..#dm_exec_query_stats') IS NOT NULL
			DROP TABLE #dm_exec_query_stats;
		CREATE TABLE #dm_exec_query_stats
			(
			  [id] [int] NOT NULL
						 IDENTITY(1, 1) ,
			  [sql_handle] [varbinary](64) NOT NULL ,
			  [statement_start_offset] [int] NOT NULL ,
			  [statement_end_offset] [int] NOT NULL ,
			  [plan_generation_num] [bigint] NOT NULL ,
			  [plan_handle] [varbinary](64) NOT NULL ,
			  [creation_time] [datetime] NOT NULL ,
			  [last_execution_time] [datetime] NOT NULL ,
			  [execution_count] [bigint] NOT NULL ,
			  [total_worker_time] [bigint] NOT NULL ,
			  [last_worker_time] [bigint] NOT NULL ,
			  [min_worker_time] [bigint] NOT NULL ,
			  [max_worker_time] [bigint] NOT NULL ,
			  [total_physical_reads] [bigint] NOT NULL ,
			  [last_physical_reads] [bigint] NOT NULL ,
			  [min_physical_reads] [bigint] NOT NULL ,
			  [max_physical_reads] [bigint] NOT NULL ,
			  [total_logical_writes] [bigint] NOT NULL ,
			  [last_logical_writes] [bigint] NOT NULL ,
			  [min_logical_writes] [bigint] NOT NULL ,
			  [max_logical_writes] [bigint] NOT NULL ,
			  [total_logical_reads] [bigint] NOT NULL ,
			  [last_logical_reads] [bigint] NOT NULL ,
			  [min_logical_reads] [bigint] NOT NULL ,
			  [max_logical_reads] [bigint] NOT NULL ,
			  [total_clr_time] [bigint] NOT NULL ,
			  [last_clr_time] [bigint] NOT NULL ,
			  [min_clr_time] [bigint] NOT NULL ,
			  [max_clr_time] [bigint] NOT NULL ,
			  [total_elapsed_time] [bigint] NOT NULL ,
			  [last_elapsed_time] [bigint] NOT NULL ,
			  [min_elapsed_time] [bigint] NOT NULL ,
			  [max_elapsed_time] [bigint] NOT NULL ,
			  [query_hash] [binary](8) NULL ,
			  [query_plan_hash] [binary](8) NULL ,
			  [query_plan] [xml] NULL ,
			  [query_plan_filtered] [nvarchar](MAX) NULL ,
			  [text] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
									 NULL ,
			  [text_filtered] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
											  NULL, 
				[database_name] nvarchar(128), 
				[object_name] nvarchar(129)
											  
			)

        /* Used for the default trace checks. */
        DECLARE @path NVARCHAR(256);
        SELECT @path=CAST(value as NVARCHAR(256))
            FROM sys.fn_trace_getinfo(1)
            WHERE traceid=1 AND property=2;

		/* If we're outputting CSV, don't bother checking the plan cache because we cannot export plans. */
		IF @OutputType = 'CSV'
			SET @CheckProcedureCache = 0;

		/* Sanitize our inputs */
		SELECT
			@OutputDatabaseName = QUOTENAME(@OutputDatabaseName),
			@OutputSchemaName = QUOTENAME(@OutputSchemaName),
			@OutputTableName = QUOTENAME(@OutputTableName)

		/* Get the major and minor build numbers */
		SET @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
		SELECT @ProductVersionMajor = SUBSTRING(@ProductVersion, 1,CHARINDEX('.', @ProductVersion) + 1 ),
			@ProductVersionMinor = PARSENAME(CONVERT(varchar(32), @ProductVersion), 2)


		/*
		Whew! we're finally done with the setup, and we can start doing checks.
		First, let's make sure we're actually supposed to do checks on this server.
		The user could have passed in a SkipChecks table that specified to skip ALL
		checks on this server, so let's check for that:
		*/
		IF ( ( SERVERPROPERTY('ServerName') NOT IN ( SELECT ServerName
													 FROM   #SkipChecks
													 WHERE  DatabaseName IS NULL
															AND CheckID IS NULL ) )
			 OR ( @SkipChecksTable IS NULL )
		   )
			BEGIN

				/*
				Our very first check! We'll put more comments in this one just to
				explain exactly how it works. First, we check to see if we're
				supposed to skip CheckID 1 (that's the check we're working on.)
				*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 1 )
					BEGIN

						/*
						Below, we check master.sys.databases looking for databases
						that haven't had a backup in the last week. If we find any,
						we insert them into #BlitzResults, the temp table that
						tracks our server's problems. Note that if the check does
						NOT find any problems, we don't save that. We're only
						saving the problems, not the successful checks.
						*/
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  1 AS CheckID ,
										d.[name] AS DatabaseName ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Backups Not Performed Recently' AS Finding ,
										'http://BrentOzar.com/go/nobak' AS URL ,
										'Database ' + d.Name + ' last backed up: '
										+ CAST(COALESCE(MAX(b.backup_finish_date),
														' never ') AS VARCHAR(200)) AS Details
								FROM    master.sys.databases d
										LEFT OUTER JOIN msdb.dbo.backupset b ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
																  AND b.type = 'D'
																  AND b.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on current server */
								WHERE   d.database_id <> 2  /* Bonus points if you know what that means */
										AND d.state <> 1 /* Not currently restoring, like log shipping databases */
										AND d.is_in_standby = 0 /* Not a log shipping target database */
										AND d.source_database_id IS NULL /* Excludes database snapshots */
										AND d.name NOT IN ( SELECT DISTINCT
																  DatabaseName
															FROM  #SkipChecks
															WHERE CheckID IS NULL )
										/*
										The above NOT IN filters out the databases we're not supposed to check.
										*/
								GROUP BY d.name
								HAVING  MAX(b.backup_finish_date) <= DATEADD(dd,
																  -7, GETDATE());
						/*
						And there you have it. The rest of this stored procedure works the same
						way: it asks:
						- Should I skip this check?
						- If not, do I find problems?
						- Insert the results into #BlitzResults
						This particular check is just a little bit fancy - it also has a second
						query below that checks for databases that have NEVER been backed up.
						We use CheckID #1 for both of these just because they represent the same
						problem - a database that needs a backup.
						*/

						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  1 AS CheckID ,
										d.name AS DatabaseName ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Backups Not Performed Recently' AS Finding ,
										'http://BrentOzar.com/go/nobak' AS URL ,
										( 'Database ' + d.Name
										  + ' never backed up.' ) AS Details
								FROM    master.sys.databases d
								WHERE   d.database_id <> 2 /* Bonus points if you know what that means */
										AND d.state <> 1 /* Not currently restoring, like log shipping databases */
										AND d.is_in_standby = 0 /* Not a log shipping target database */
										AND d.source_database_id IS NULL /* Excludes database snapshots */
										AND d.name NOT IN ( SELECT DISTINCT
																  DatabaseName
															FROM  #SkipChecks
															WHERE CheckID IS NULL )
										AND NOT EXISTS ( SELECT *
														 FROM   msdb.dbo.backupset b
														 WHERE  d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
																AND b.type = 'D'
																AND b.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on current server */)

					END

				/*
				And that's the end of CheckID #1.

				CheckID #2 is a little simpler because it only involves one query, and it's
				more typical for queries that people contribute. But keep reading, because
				the next check gets more complex again.
				*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 2 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										2 AS CheckID ,
										d.name AS DatabaseName ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Full Recovery Mode w/o Log Backups' AS Finding ,
										'http://BrentOzar.com/go/biglogs' AS URL ,
										( 'Database ' + ( d.Name COLLATE database_default )
										  + ' is in ' + d.recovery_model_desc
										  + ' recovery mode but has not had a log backup in the last week.' ) AS Details
								FROM    master.sys.databases d
								WHERE   d.recovery_model IN ( 1, 2 )
										AND d.database_id NOT IN ( 2, 3 )
										AND d.source_database_id IS NULL
										AND d.state <> 1 /* Not currently restoring, like log shipping databases */
										AND d.is_in_standby = 0 /* Not a log shipping target database */
										AND d.source_database_id IS NULL /* Excludes database snapshots */
										AND d.name NOT IN ( SELECT DISTINCT
																  DatabaseName
															FROM  #SkipChecks
															WHERE CheckID IS NULL )
										AND NOT EXISTS ( SELECT *
														 FROM   msdb.dbo.backupset b
														 WHERE  d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
																AND b.type = 'L'
																AND b.backup_finish_date >= DATEADD(dd,
																  -7, GETDATE()) );
					END


				/*
				Next up, we've got CheckID 8. (These don't have to go in order.) This one
				won't work on SQL Server 2005 because it relies on a new DMV that didn't
				exist prior to SQL Server 2008. This means we have to check the SQL Server
				version first, then build a dynamic string with the query we want to run:
				*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 8 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID, Priority,
							FindingsGroup,
							Finding, URL,
							Details)
					  SELECT 8 AS CheckID,
					  150 AS Priority,
					  ''Security'' AS FindingsGroup,
					  ''Server Audits Running'' AS Finding,
					  ''http://BrentOzar.com/go/audits'' AS URL,
					  (''SQL Server built-in audit functionality is being used by server audit: '' + [name]) AS Details FROM sys.dm_server_audit_status'
								EXECUTE(@StringToExecute)
							END;
					END

				/*
				But what if you need to run a query in every individual database?
				Check out CheckID 99 below. Yes, it uses sp_MSforeachdb, and no,
				we're not happy about that. sp_MSforeachdb is known to have a lot
				of issues, like skipping databases sometimes. However, this is the
				only built-in option that we have. If you're writing your own code
				for database maintenance, consider Aaron Bertrand's alternative:
				http://www.mssqltips.com/sqlservertip/2201/making-a-more-reliable-and-flexible-spmsforeachdb/
				We don't include that as part of sp_Blitz, of course, because
				copying and distributing copyrighted code from others without their
				written permission isn't a good idea.
				*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 99 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'USE [?];  IF EXISTS (SELECT * FROM  sys.tables WITH (NOLOCK) WHERE name = ''sysmergepublications'' ) 
						IF EXISTS ( SELECT * FROM sysmergepublications WITH (NOLOCK) WHERE retention = 0)   
						INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 99, DB_NAME(), 110, ''Performance'', 
''Infinite merge replication metadata retention period'', ''http://BrentOzar.com/go/merge'',
 (''The ['' + DB_NAME() + ''] database has merge replication metadata retention period set to infinite - this can be the case of significant performance issues.'')';
					END
				/*
				Note that by using sp_MSforeachdb, we're running the query in all
				databases. We're not checking #SkipChecks here for each database to
				see if we should run the check in this database. That means we may
				still run a skipped check if it involves sp_MSforeachdb. We just
				don't output those results in the last step.

				And that's the basic idea! You can read through the rest of the
				checks if you like - some more exciting stuff happens closer to the
				end of the stored proc, where we start doing things like checking
				the plan cache, but those aren't as cleanly commented.

				If you'd like to contribute your own check, use one of the check
				formats shown above and email it to Help@BrentOzar.com. You don't
				have to pick a CheckID or a link - we'll take care of that when we
				test and publish the code. Thanks!
				*/


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 93 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										93 AS CheckID ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Backing Up to Same Drive Where Databases Reside' AS Finding ,
										'http://BrentOzar.com/go/backup' AS URL ,
										'Drive '
										+ UPPER(LEFT(bmf.physical_device_name, 3))
										+ ' houses both database files AND backups taken in the last two weeks. This represents a serious risk if that array fails.' Details
								FROM    msdb.dbo.backupmediafamily AS bmf
										INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id
																  AND bs.backup_start_date >= ( DATEADD(dd,
																  -14, GETDATE()) )
								WHERE   UPPER(LEFT(bmf.physical_device_name COLLATE SQL_Latin1_General_CP1_CI_AS, 3)) IN (
										SELECT DISTINCT
												UPPER(LEFT(mf.physical_name COLLATE SQL_Latin1_General_CP1_CI_AS, 3))
										FROM    sys.master_files AS mf )
					END


					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 119 )
						AND EXISTS ( SELECT *
									 FROM   sys.all_objects o
									 WHERE  o.name = 'dm_database_encryption_keys' )
						BEGIN
							SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, DatabaseName, URL, Details)
								SELECT 119 AS CheckID,
								1 AS Priority,
								''Backup'' AS FindingsGroup,
								''TDE Certificate Not Backed Up Recently'' AS Finding,
								db_name(dek.database_id) AS DatabaseName,
								''http://BrentOzar.com/go/tde'' AS URL,
								''The certificate '' + c.name + '' is used to encrypt database '' + db_name(dek.database_id) + ''. Last backup date: ''
								 + COALESCE(CAST(c.pvt_key_last_backup_date AS VARCHAR(100)), ''Never'') AS Details
								FROM sys.certificates c INNER JOIN sys.dm_database_encryption_keys dek ON c.thumbprint = dek.encryptor_thumbprint
								WHERE pvt_key_last_backup_date IS NULL OR pvt_key_last_backup_date <= DATEADD(dd, -30, GETDATE())';
							EXECUTE(@StringToExecute);
						END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 3 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										3 AS CheckID ,
										'msdb' ,
										200 AS Priority ,
										'Backup' AS FindingsGroup ,
										'MSDB Backup History Not Purged' AS Finding ,
										'http://BrentOzar.com/go/history' AS URL ,
										( 'Database backup history retained back to '
										  + CAST(bs.backup_start_date AS VARCHAR(20)) ) AS Details
								FROM    msdb.dbo.backupset bs
								WHERE   bs.backup_start_date <= DATEADD(dd, -60,
																  GETDATE())
								ORDER BY backup_set_id ASC;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 4 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  4 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Sysadmins' AS Finding ,
										'http://BrentOzar.com/go/sa' AS URL ,
										( 'Login [' + l.name
										  + '] is a sysadmin - meaning they can do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) AS Details
								FROM    master.sys.syslogins l
								WHERE   l.sysadmin = 1
										AND l.name <> SUSER_SNAME(0x01)
										AND l.denylogin = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 5 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  5 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Security Admins' AS Finding ,
										'http://BrentOzar.com/go/sa' AS URL ,
										( 'Login [' + l.name
							+ '] is a security admin - meaning they can give themselves permission to do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) 
										  AS Details
								FROM    master.sys.syslogins l
								WHERE   l.securityadmin = 1
										AND l.name <> SUSER_SNAME(0x01)
										AND l.denylogin = 0;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 104 )
					BEGIN
						INSERT  INTO #BlitzResults
								( [CheckID] ,
								  [Priority] ,
								  [FindingsGroup] ,
								  [Finding] ,
								  [URL] ,
								  [Details]
								)
								SELECT  104 AS [CheckID] ,
										10 AS [Priority] ,
										'Security' AS [FindingsGroup] ,
										'Login Can Control Server' AS [Finding] ,
										'http://BrentOzar.com/go/sa' AS [URL] ,
										'Login [' + pri.[name]
										+ '] has the CONTROL SERVER permission - meaning they can do absolutely anything in SQL Server, including dropping databases or hiding their tracks.'
										 AS [Details]
								FROM    sys.server_principals AS pri
								WHERE   pri.[principal_id] IN (
										SELECT  p.[grantee_principal_id]
										FROM    sys.server_permissions AS p
										WHERE   p.[state] IN ( 'G', 'W' )
												AND p.[class] = 100
												AND p.[type] = 'CL' )
										AND pri.[name] NOT LIKE '##%##'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 6 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  6 AS CheckID ,
										200 AS Priority ,
										'Security' AS FindingsGroup ,
										'Jobs Owned By Users' AS Finding ,
										'http://BrentOzar.com/go/owners' AS URL ,
										( 'Job [' + j.name + '] is owned by ['
										  + SUSER_SNAME(j.owner_sid)
										  + '] - meaning if their login is disabled or not available due to Active Directory problems, the job will stop working.' ) AS Details
								FROM    msdb.dbo.sysjobs j
								WHERE   j.enabled = 1
										AND SUSER_SNAME(j.owner_sid) <> SUSER_SNAME(0x01);
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 7 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  7 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Stored Procedure Runs at Startup' AS Finding ,
										'http://BrentOzar.com/go/startup' AS URL ,
										( 'Stored procedure [master].['
										  + r.SPECIFIC_SCHEMA + '].['
										  + r.SPECIFIC_NAME
										  + '] runs automatically when SQL Server starts up.  Make sure you know exactly what this stored procedure is doing, because it could pose a security risk.' ) AS Details
								FROM    master.INFORMATION_SCHEMA.ROUTINES r
								WHERE   OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),
													   'ExecIsStartup') = 1;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 9 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 9 AS CheckID,
					  200 AS Priority,
					  ''Surface Area'' AS FindingsGroup,
					  ''Endpoints Configured'' AS Finding,
					  ''http://BrentOzar.com/go/endpoints/'' AS URL,
					  (''SQL Server endpoints are configured.  These can be used for database mirroring or Service Broker, but if you do not need them, avoid leaving them enabled.  Endpoint name: '' + [name]) AS Details FROM sys.endpoints WHERE type <> 2'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 10 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 10 AS CheckID,
					  100 AS Priority,
					  ''Performance'' AS FindingsGroup,
					  ''Resource Governor Enabled'' AS Finding,
					  ''http://BrentOzar.com/go/rg'' AS URL,
					  (''Resource Governor is enabled.  Queries may be throttled.  Make sure you understand how the Classifier Function is configured.'') AS Details FROM sys.resource_governor_configuration WHERE is_enabled = 1'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 11 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 11 AS CheckID,
					  100 AS Priority,
					  ''Performance'' AS FindingsGroup,
					  ''Server Triggers Enabled'' AS Finding,
					  ''http://BrentOzar.com/go/logontriggers/'' AS URL,
					  (''Server Trigger ['' + [name] ++ ''] is enabled, so it runs every time someone logs in.  Make sure you understand what that trigger is doing - the less work it does, the better.'') AS Details FROM sys.server_triggers WHERE is_disabled = 0 AND is_m
s_shipped = 0'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 12 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  12 AS CheckID ,
										[name] AS DatabaseName ,
										10 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Close Enabled' AS Finding ,
										'http://BrentOzar.com/go/autoclose' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-close enabled.  This setting can dramatically decrease performance.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_close_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 13 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  13 AS CheckID ,
										[name] AS DatabaseName ,
										10 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Shrink Enabled' AS Finding ,
										'http://BrentOzar.com/go/autoshrink' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-shrink enabled.  This setting can dramatically decrease performance.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_shrink_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 14 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							DatabaseName,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 14 AS CheckID,
					  [name] as DatabaseName,
					  50 AS Priority,
					  ''Reliability'' AS FindingsGroup,
					  ''Page Verification Not Optimal'' AS Finding,
					  ''http://BrentOzar.com/go/torn'' AS URL,
					  (''Database ['' + [name] + ''] has '' + [page_verify_option_desc] + '' for page verification.  SQL Server may have a harder time recognizing and recovering from storage corruption.  Consider using CHECKSUM instead.'') COLLATE database_default AS De
tails
					  FROM sys.databases
					  WHERE page_verify_option < 2
					  AND name <> ''tempdb''
					  and name not in (select distinct DatabaseName from #SkipChecks)'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 15 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  15 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Create Stats Disabled' AS Finding ,
										'http://BrentOzar.com/go/acs' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-create-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically create more, performance may suffer.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_create_stats_on = 0
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 16 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  16 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Update Stats Disabled' AS Finding ,
										'http://BrentOzar.com/go/aus' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-update-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically update them, performance may suffer.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_update_stats_on = 0
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 17 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  17 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Stats Updated Asynchronously' AS Finding ,
										'http://BrentOzar.com/go/asyncstats' AS URL ,
										( 'Database [' + [name]+ '] has auto-update-stats-async enabled.  When SQL Server gets a query for a table with out-of-date statistics, it will run the query with the stats it has - while updating stats to make later queries better. The initial 
run of the query may 
suffer, though.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_update_stats_async_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 18 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  18 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Forced Parameterization On' AS Finding ,
										'http://BrentOzar.com/go/forced' AS URL ,
										( 'Database [' + [name]
										  + '] has forced parameterization enabled.  SQL Server will aggressively reuse query execution plans even if the applications do not parameterize their queries.  This can be a performance booster with some programming languages, or it may use u
niversally bad execution plans when better alternatives are available for certain parameters.' ) 
										  AS Details
								FROM    sys.databases
								WHERE   is_parameterization_forced = 1
										AND name NOT IN ( SELECT  DatabaseName
														  FROM    #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 19 )
					BEGIN
						/* Method 1: Check sys.databases parameters */
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)

								SELECT  19 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Replication In Use' AS Finding ,
										'http://BrentOzar.com/go/repl' AS URL ,
										( 'Database [' + [name]
										  + '] is a replication publisher, subscriber, or distributor.' ) AS Details
								FROM    sys.databases
								WHERE   name NOT IN ( SELECT DISTINCT
																DatabaseName
													  FROM      #SkipChecks )
										AND is_published = 1
										OR is_subscribed = 1
										OR is_merge_published = 1
										OR is_distributor = 1;

						/* Method B: check subscribers for MSreplication_objects tables */
						EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults
										(CheckID,
										DatabaseName,
										Priority,
										FindingsGroup,
										Finding,
										URL,
										Details)
							  SELECT DISTINCT 19,
							  db_name(),
							  200,
							  ''Informational'',
							  ''Replication In Use'',
							  ''http://BrentOzar.com/go/repl'',
							  (''['' + DB_NAME() + ''] has MSreplication_objects tables in it, indicating it is a replication subscriber.'')
							  FROM [?].sys.tables
							  WHERE name = ''dbo.MSreplication_objects'' AND ''?'' <> ''master''';

					END

				IF NOT EXISTS ( SELECT  1
								FROM #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 20 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  20 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Date Correlation On' AS Finding ,
										'http://BrentOzar.com/go/corr' AS URL ,
										( 'Database [' + [name]
										  + '] has date correlation enabled.  This is not a default setting, and it has some performance overhead.  It tells SQL Server that date fields in two tables are related, and SQL Server maintains statistics showing that relation.' ) AS Details


								FROM    sys.databases
								WHERE   is_date_correlation_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 21 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							DatabaseName,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 21 AS CheckID,
					  [name] as DatabaseName,
					  20 AS Priority,
					  ''Encryption'' AS FindingsGroup,
					  ''Database Encrypted'' AS Finding,
					  ''http://BrentOzar.com/go/tde'' AS URL,
					  (''Database ['' + [name] + ''] has Transparent Data Encryption enabled.  Make absolutely sure you have backed up the certificate and private key, or else you will not be able to restore this database.'') AS Details
					  FROM sys.databases
					  WHERE is_encrypted = 1
					  and name not in (select distinct DatabaseName from #SkipChecks)'
								EXECUTE(@StringToExecute)
							END;
					END

				/*
				Believe it or not, SQL Server doesn't track the default values
				for sp_configure options! We'll make our own list here.
				*/
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'access check cache bucket count', 0, 1001 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'access check cache quota', 0, 1002 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Ad Hoc Distributed Queries', 0, 1003 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity I/O mask', 0, 1004 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity mask', 0, 1005 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Agent XPs', 0, 1006 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'allow updates', 0, 1007 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'awe enabled', 0, 1008 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'blocked process threshold', 0, 1009 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'c2 audit mode', 0, 1010 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'clr enabled', 0, 1011 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cost threshold for parallelism', 5, 1012 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cross db ownership chaining', 0, 1013 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cursor threshold', -1, 1014 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Database Mail XPs', 0, 1015 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default full-text language', 1033, 1016 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default language', 0, 1017 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default trace enabled', 1, 1018 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'disallow results from triggers', 0, 1019 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'fill factor (%)', 0, 1020 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft crawl bandwidth (max)', 100, 1021 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft crawl bandwidth (min)', 0, 1022 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft notify bandwidth (max)', 100, 1023 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft notify bandwidth (min)', 0, 1024 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'index create memory (KB)', 0, 1025 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'in-doubt xact resolution', 0, 1026 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'lightweight pooling', 0, 1027 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'locks', 0, 1028 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max degree of parallelism', 0, 1029 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max full-text crawl range', 4, 1030 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max server memory (MB)', 2147483647, 1031 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max text repl size (B)', 65536, 1032 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max worker threads', 0, 1033 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'media retention', 0, 1034 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'min memory per query (KB)', 1024, 1035 );
				/* Accepting both 0 and 16 below because both have been seen in the wild as defaults. */
				IF EXISTS ( SELECT  *
							FROM    sys.configurations
							WHERE   name = 'min server memory (MB)'
									AND value_in_use IN ( 0, 16 ) )
					INSERT  INTO #ConfigurationDefaults
							SELECT  'min server memory (MB)' ,
									CAST(value_in_use AS BIGINT), 1036
							FROM    sys.configurations
							WHERE   name = 'min server memory (MB)'
				ELSE
					INSERT  INTO #ConfigurationDefaults
					VALUES  ( 'min server memory (MB)', 0, 1036 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'nested triggers', 1, 1037 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'network packet size (B)', 4096, 1038 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Ole Automation Procedures', 0, 1039 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'open objects', 0, 1040 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'optimize for ad hoc workloads', 0, 1041 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'PH timeout (s)', 60, 1042 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'precompute rank', 0, 1043 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'priority boost', 0, 1044 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'query governor cost limit', 0, 1045 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'query wait (s)', -1, 1046 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'recovery interval (min)', 0, 1047 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote access', 1, 1048 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote admin connections', 0, 1049 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote proc trans', 0, 1050 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote query timeout (s)', 600, 1051 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Replication XPs', 0, 1052 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'RPC parameter data validation', 0, 1053 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'scan for startup procs', 0, 1054 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'server trigger recursion', 1, 1055 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'set working set size', 0, 1056 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'show advanced options', 0, 1057 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'SMO and DMO XPs', 1, 1058 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'SQL Mail XPs', 0, 1059 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'transform noise words', 0, 1060 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'two digit year cutoff', 2049, 1061 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'user connections', 0, 1062 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'user options', 0, 1063 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Web Assistant Procedures', 0, 1064 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'xp_cmdshell', 0, 1065 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity64 mask', 0, 1066 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity64 I/O mask', 0, 1067 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'contained database authentication', 0, 1068 );
				/* SQL Server 2012 also changes a configuration default */
				IF @@VERSION LIKE '%Microsoft SQL Server 2005%'
					OR @@VERSION LIKE '%Microsoft SQL Server 2008%'
					BEGIN
						INSERT  INTO #ConfigurationDefaults
						VALUES  ( 'remote login timeout (s)', 20, 1069 );
					END
				ELSE
					BEGIN
						INSERT  INTO #ConfigurationDefaults
						VALUES  ( 'remote login timeout (s)', 10, 1070 );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 22 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  cd.CheckID ,
										200 AS Priority ,
										'Non-Default Server Config' AS FindingsGroup ,
										cr.name AS Finding ,
										'http://BrentOzar.com/go/conf' AS URL ,
										( 'This sp_configure option has been changed.  Its default value is '
										  + COALESCE(CAST(cd.[DefaultValue] AS VARCHAR(100)),
													 '(unknown)')
										  + ' and it has been set to '
										  + CAST(cr.value_in_use AS VARCHAR(100))
										  + '.' ) AS Details
								FROM    sys.configurations cr
										INNER JOIN #ConfigurationDefaults cd ON cd.name = cr.name
										LEFT OUTER JOIN #ConfigurationDefaults cdUsed ON cdUsed.name = cr.name
																  AND cdUsed.DefaultValue = cr.value_in_use
								WHERE   cdUsed.name IS NULL;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 24 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										24 AS CheckID ,
										DB_NAME(database_id) AS DatabaseName ,
										20 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'System Database on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										( 'The ' + DB_NAME(database_id)
										  + ' database has a file on the C drive.  Putting system databases on the C drive runs the risk of crashing the server when it runs out of space.' ) 
										  AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) IN ( 'master',
																  'model', 'msdb' );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 25 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										25 AS CheckID ,
										'tempdb' ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'TempDB on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										CASE WHEN growth > 0
											 THEN ( 'The tempdb database has files on the C drive.  TempDB frequently grows unpredictably, putting your server at risk of running out of C drive space and crashing hard.  C is also often much slower than other drives, so performance may be 

suffering.' )
									 ELSE ( 'The tempdb database has files on the C drive.  TempDB is not set to Autogrow, hopefully it is big enough.  C is also often much slower than other drives, so performance may be suffering.' )
										END AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) = 'tempdb';
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 26 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										26 AS CheckID ,
										DB_NAME(database_id) AS DatabaseName ,
										20 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'User Databases on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										( 'The ' + DB_NAME(database_id)
										  + ' database has a file on the C drive.  Putting databases on the C drive runs the risk of crashing the server when it runs out of space.' ) AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) NOT IN ( 'master',
																  'model', 'msdb',
																  'tempdb' )
										AND DB_NAME(database_id) NOT IN (
										SELECT DISTINCT
												DatabaseName
										FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 27 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  27 AS CheckID ,
										'master' AS DatabaseName ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the Master Database' AS Finding ,
										'http://BrentOzar.com/go/mastuser' AS URL ,
										( 'The ' + name
										  + ' table in the master database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the master database may not be restored in the event of a disaster.' ) AS Details
								FROM    master.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 28 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  28 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the MSDB Database' AS Finding ,
										'http://BrentOzar.com/go/msdbuser' AS URL ,
										( 'The ' + name
										  + ' table in the msdb database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the msdb database may not be restored in the event of a disaster.' ) AS Details
								FROM    msdb.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 29 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  29 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the Model Database' AS Finding ,
										'http://BrentOzar.com/go/model' AS URL ,
										( 'The ' + name
										  + ' table in the model database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the model database are automatically copied into all new databases.' ) AS Details
								FROM    model.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 30 )
					BEGIN
						IF ( SELECT COUNT(*)
							 FROM   msdb.dbo.sysalerts
							 WHERE  severity BETWEEN 19 AND 25
						   ) < 7
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  30 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Not All Alerts Configured' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'Not all SQL Server Agent alerts have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
					END



				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 59 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 1
											AND COALESCE(has_notification, 0) = 0
											AND (job_id IS NULL OR job_id = 0x))
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  59 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Alerts Configured without Follow Up' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts have been configured but they either do not notify anyone or else they do not take any action.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pic
k it up.' ) AS Details;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 96 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysalerts
										WHERE   message_id IN ( 823, 824, 825 ) )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  96 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Alerts for Corruption' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts do not exist for errors 823, 824, and 825.  These three errors can give you notification about early hardware failure. Enabling them can prevent you a lot of heartbreak.' ) AS Details;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 61 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysalerts
										WHERE   severity BETWEEN 19 AND 25 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  61 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Alerts for Sev 19-25' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts do not exist for severity levels 19 through 25.  These are some very severe SQL Server errors. Knowing that these are happening may let you recover from errors faster.' ) AS Details;
					END

		--check for disabled alerts
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 98 )
					BEGIN
						IF EXISTS ( SELECT  name
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 0 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  98 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Alerts Disabled' AS Finding ,
											'http://www.BrentOzar.com/go/alerts/' AS URL ,
											( 'The following Alert is disabled, please review and enable if desired: '
											  + name ) AS Details
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 0
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 31 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysoperators
										WHERE   enabled = 1 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  31 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Operators Configured/Enabled' AS Finding ,
											'http://BrentOzar.com/go/op' AS URL ,
											( 'No SQL Server Agent operators (emails) have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 33 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults
					(CheckID,
					DatabaseName,
					Priority,
					FindingsGroup,
					Finding,
					URL,
					Details)
		  SELECT DISTINCT 33,
		  db_name(),
		  200,
		  ''Licensing'',
		  ''Enterprise Edition Features In Use'',
		  ''http://BrentOzar.com/go/ee'',
		  (''The ['' + DB_NAME() + ''] database is using '' + feature_name + ''.  If this database is restored onto a Standard Edition server, the restore will fail.'')
		  FROM [?].sys.dm_db_persisted_sku_features';
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 34 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    sys.all_objects
									WHERE   name = 'dm_db_mirroring_auto_page_repair' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  34 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''Database mirroring has automatically repaired at least one corrupt page in the last 30 days. For more information, query the DMV sys.dm_db_mirroring_auto_page_repair.'' ) AS Details
		  FROM (SELECT rp2.database_id, rp2.modification_time 
			FROM sys.dm_db_mirroring_auto_page_repair rp2 
			WHERE rp2.[database_id] not in (
			SELECT db2.[database_id] 
			FROM sys.databases as db2 
			WHERE db2.[state] = 1
			) ) as rp 
		  INNER JOIN master.sys.databases db ON rp.database_id = db.database_id
		  WHERE   rp.modification_time >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 89 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    sys.all_objects
									WHERE   name = 'dm_hadr_auto_page_repair' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  89 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''AlwaysOn has automatically repaired at least one corrupt page in the last 30 days. For more information, query the DMV sys.dm_hadr_auto_page_repair.'' ) AS Details
		  FROM    sys.dm_hadr_auto_page_repair rp
		  INNER JOIN master.sys.databases db ON rp.database_id = db.database_id
		  WHERE   rp.modification_time >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 90 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    msdb.sys.all_objects
									WHERE   name = 'suspect_pages' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  90 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''SQL Server has detected at least one corrupt page in the last 30 days. For more information, query the system table msdb.dbo.suspect_pages.'' ) AS Details
		  FROM    msdb.dbo.suspect_pages sp
		  INNER JOIN master.sys.databases db ON sp.database_id = db.database_id
		  WHERE   sp.last_update_date >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 36 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										36 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Slow Storage Reads on Drive '
										+ UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
										'http://BrentOzar.com/go/slow' AS URL ,
										'Reads are averaging longer than 100ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' 										AS Details
								FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
										AS fs
										INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
																  AND fs.[file_id] = mf.[file_id]
								WHERE   ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) > 100;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 37 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										37 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Slow Storage Writes on Drive '
										+ UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
										'http://BrentOzar.com/go/slow' AS URL ,
										'Writes are averaging longer than 20ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' 										AS Details
								FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
										AS fs
										INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
																  AND fs.[file_id] = mf.[file_id]
								WHERE   ( io_stall_write_ms / ( 1.0
																+ num_of_writes ) ) > 20;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 40 )
					BEGIN
						IF ( SELECT COUNT(*)
							 FROM   tempdb.sys.database_files
							 WHERE  type_desc = 'ROWS'
						   ) = 1
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  DatabaseName ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
								VALUES  ( 40 ,
										  'tempdb' ,
										  100 ,
										  'Performance' ,
										  'TempDB Only Has 1 Data File' ,
										  'http://BrentOzar.com/go/tempdb' ,
										  'TempDB is only configured with one data file.  More data files are usually required to alleviate SGAM contention.'
										);
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 41 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'use [?];
		  INSERT INTO #BlitzResults
		  (CheckID,
		  DatabaseName,
		  Priority,
		  FindingsGroup,
		  Finding,
		  URL,
		  Details)
		  SELECT 41,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Multiple Log Files on One Drive'',
		  ''http://BrentOzar.com/go/manylogs'',
		  (''The ['' + DB_NAME() + ''] database has multiple log files on the '' + LEFT(physical_name, 1) 
		  + '' drive. This is not a performance booster because log file access is sequential, not parallel.'')
		  FROM [?].sys.database_files WHERE type_desc = ''LOG''
			AND ''?'' <> ''[tempdb]''
		  GROUP BY LEFT(physical_name, 1)
		  HAVING COUNT(*) > 1';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 42 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'use [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
			SELECT DISTINCT 42,
			''?'',
			100,
			''Performance'',
			''Uneven File Growth Settings in One Filegroup'',
			''http://BrentOzar.com/go/grow'',
			(''The ['' + DB_NAME() + ''] database has multiple data files in one filegroup, but they are not all set up to grow in identical amounts.  This can lead to uneven file activity inside the filegroup.'')
			FROM [?].sys.database_files
			WHERE type_desc = ''ROWS''
			GROUP BY data_space_id
			HAVING COUNT(DISTINCT growth) > 1 OR COUNT(DISTINCT is_percent_growth) > 1';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 44 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  44 AS CheckID ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Queries Forcing Order Hints' AS Finding ,
										'http://BrentOzar.com/go/hints' AS URL ,
										CAST(occurrence AS VARCHAR(10))
										+ ' instances of order hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tun
ing efforts aren''t working.' AS Details
								FROM    sys.dm_exec_query_optimizer_info
								WHERE   counter = 'order hint'
										AND occurrence > 1
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 45 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  45 AS CheckID ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Queries Forcing Join Hints' AS Finding ,
										'http://BrentOzar.com/go/hints' AS URL ,
										CAST(occurrence AS VARCHAR(10))
										+ ' instances of join hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tuni
ng efforts aren''t working.' AS Details
								FROM    sys.dm_exec_query_optimizer_info
								WHERE   counter = 'join hint'
										AND occurrence > 1
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 49 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										49 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Linked Server Configured' AS Finding ,
										'http://BrentOzar.com/go/link' AS URL ,
										+CASE WHEN l.remote_name = 'sa'
											  THEN s.data_source
												   + ' is configured as a linked server. Check its security configuration as it is connecting with sa, because any user who queries it will get admin-level permissions.'
											  ELSE s.data_source
												   + ' is configured as a linked server. Check its security configuration to make sure it isn''t connecting with SA or some other bone-headed administrative login, because any user who queries it might get admin-level permissions.'
										 END AS Details
								FROM    sys.servers s
										INNER JOIN sys.linked_logins l ON s.server_id = l.server_id
								WHERE   s.is_linked = 1
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 50 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
		  SELECT  50 AS CheckID ,
		  100 AS Priority ,
		  ''Performance'' AS FindingsGroup ,
		  ''Max Memory Set Too High'' AS Finding ,
		  ''http://BrentOzar.com/go/max'' AS URL ,
		  ''SQL Server max memory is set to ''
			+ CAST(c.value_in_use AS VARCHAR(20))
			+ '' megabytes, but the server only has ''
			+ CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
			+ '' megabytes.  SQL Server may drain the system dry of memory, and under certain conditions, this can cause Windows to swap to disk.'' AS Details
		  FROM    sys.dm_os_sys_memory m
		  INNER JOIN sys.configurations c ON c.name = ''max server memory (MB)''
		  WHERE   CAST(m.total_physical_memory_kb AS BIGINT) < ( CAST(c.value_in_use AS BIGINT) * 1024 )'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 51 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
		  SELECT  51 AS CheckID ,
		  1 AS Priority ,
		  ''Performance'' AS FindingsGroup ,
		  ''Memory Dangerously Low'' AS Finding ,
		  ''http://BrentOzar.com/go/max'' AS URL ,
		  ''The server has '' + CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20)) + '' megabytes of physical memory, but only '' 
		  + CAST(( CAST(m.available_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
			+ '' megabytes are available.  As the server runs out of memory, there is danger of swapping to disk, which will kill performance.'' AS Details
		  FROM    sys.dm_os_sys_memory m
		  WHERE   CAST(m.available_physical_memory_kb AS BIGINT) < 262144'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 53 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										53 AS CheckID ,
										200 AS Priority ,
										'High Availability' AS FindingsGroup ,
										'Cluster Node' AS Finding ,
										'http://BrentOzar.com/go/node' AS URL ,
										'This is a node in a cluster.' AS Details
								FROM    sys.dm_os_cluster_nodes
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 55 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  55 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Security' AS FindingsGroup ,
										'Database Owner <> SA' AS Finding ,
										'http://BrentOzar.com/go/owndb' AS URL ,
										( 'Database name: ' + [name] + '   '
										  + 'Owner name: ' + SUSER_SNAME(owner_sid) ) AS Details
								FROM    sys.databases
								WHERE   SUSER_SNAME(owner_sid) <> SUSER_SNAME(0x01)
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks );
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 57 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  57 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'SQL Agent Job Runs at Startup' AS Finding ,
										'http://BrentOzar.com/go/startup' AS URL ,
										( 'Job [' + j.name
										  + '] runs automatically when SQL Server Agent starts up.  Make sure you know exactly what this job is doing, because it could pose a security risk.' ) 
										  AS Details
								FROM    msdb.dbo.sysschedules sched
										JOIN msdb.dbo.sysjobschedules jsched ON sched.schedule_id = jsched.schedule_id
										JOIN msdb.dbo.sysjobs j ON jsched.job_id = j.job_id
								WHERE   sched.freq_type = 64;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 82 )
					BEGIN
						EXEC sp_MSforeachdb 'use [?];
		INSERT INTO #BlitzResults
		(CheckID,
		DatabaseName,
		Priority,
		FindingsGroup,
		Finding,
		URL, Details)
		SELECT  DISTINCT 82 AS CheckID,
		''?'' as DatabaseName,
		100 AS Priority,
		''Performance'' AS FindingsGroup,
		''File growth set to percent'',
		''http://brentozar.com/go/percentgrowth'' AS URL,
		''The ['' + DB_NAME() + ''] database is using percent filegrowth settings. This can lead to out of control filegrowth.''
		FROM    [?].sys.database_files
		WHERE   is_percent_growth = 1 ';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 97 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  97 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Unusual SQL Server Edition' AS Finding ,
										'http://BrentOzar.com/go/workgroup' AS URL ,
										( 'This server is using '
										  + CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
										  + ', which is capped at low amounts of CPU and memory.' ) AS Details
								WHERE   CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Standard%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Enterprise%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Developer%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Business Intelligence%'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 62 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  62 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Old Compatibility Level' AS Finding ,
										'http://BrentOzar.com/go/compatlevel' AS URL ,
										( 'Database ' + [name]
										  + ' is compatibility level '
										  + CAST(compatibility_level AS VARCHAR(20))
										  + ', which may cause unwanted results when trying to run queries that have newer T-SQL features.' ) AS Details
								FROM    sys.databases
								WHERE   name NOT IN ( SELECT DISTINCT
																DatabaseName
													  FROM      #SkipChecks )
										AND compatibility_level <> ( SELECT
																  compatibility_level
																  FROM
																  sys.databases
																  WHERE
																  [name] = 'model'
																  )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 94 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  94 AS CheckID ,
										50 AS [Priority] ,
										'Reliability' AS FindingsGroup ,
										'Agent Jobs Without Failure Emails' AS Finding ,
										'http://BrentOzar.com/go/alerts' AS URL ,
										'The job ' + [name]
										+ ' has not been set up to notify an operator if it fails.' AS Details
								FROM    msdb.[dbo].[sysjobs] j
										INNER JOIN ( SELECT DISTINCT
															[job_id]
													 FROM   [msdb].[dbo].[sysjobschedules]
													 WHERE  next_run_date > 0
												   ) s ON j.job_id = s.job_id
								WHERE   j.enabled = 1
										AND j.notify_email_operator_id = 0
										AND j.notify_netsend_operator_id = 0
										AND j.notify_page_operator_id = 0
										AND j.category_id <> 100 /* Exclude SSRS category */
					END


				IF EXISTS ( SELECT  1
							FROM    sys.configurations
							WHERE   name = 'remote admin connections'
									AND value_in_use = 0 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 100 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  100 AS CheckID ,
										50 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Remote DAC Disabled' AS Finding ,
										'http://BrentOzar.com/go/dac' AS URL ,
										'Remote access to the Dedicated Admin Connection (DAC) is not enabled. The DAC can make remote troubleshooting much easier when SQL Server is unresponsive.'
					END


				IF EXISTS ( SELECT  *
							FROM    sys.dm_os_schedulers
							WHERE   is_online = 0 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 101 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  101 AS CheckID ,
										50 AS Priority ,
										'Performance' AS FindingGroup ,
										'CPU Schedulers Offline' AS Finding ,
										'http://BrentOzar.com/go/schedulers' AS URL ,
										'Some CPU cores are not accessible to SQL Server due to affinity masking or licensing problems.'
					END


					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 110 )
								AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'dm_os_memory_nodes')
						BEGIN
							SET @StringToExecute = 'IF EXISTS (SELECT  *
												FROM sys.dm_os_nodes n
												INNER JOIN sys.dm_os_memory_nodes m ON n.memory_node_id = m.memory_node_id
												WHERE n.node_state_desc = ''OFFLINE'')
												INSERT  INTO #BlitzResults
														( CheckID ,
														  Priority ,
														  FindingsGroup ,
														  Finding ,
														  URL ,
														  Details
														)
														SELECT  110 AS CheckID ,
																50 AS Priority ,
																''Performance'' AS FindingGroup ,
																''Memory Nodes Offline'' AS Finding ,
																''http://BrentOzar.com/go/schedulers'' AS URL ,
																''Due to affinity masking or licensing problems, some of the memory may not be available.''';
									EXECUTE(@StringToExecute);
						END


				IF EXISTS ( SELECT  *
							FROM    sys.databases
							WHERE   state > 1 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 102 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  102 AS CheckID ,
										[name] ,
										20 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Unusual Database State: ' + [state_desc] AS Finding ,
										'http://BrentOzar.com/go/repair' AS URL ,
										'This database may not be online.'
								FROM    sys.databases
								WHERE   state > 1
					END

				IF EXISTS ( SELECT  *
							FROM    master.sys.extended_procedures )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 105 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  105 AS CheckID ,
										'master' ,
										50 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Extended Stored Procedures in Master' AS Finding ,
										'http://BrentOzar.com/go/clr' AS URL ,
										'The [' + name
										+ '] extended stored procedure is in the master database. CLR may be in use, and the master database now needs to be part of your backup/recovery planning.'
								FROM    master.sys.extended_procedures
					END



					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 107 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  107 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: THREADPOOL'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'THREADPOOL'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END

					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 108 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  108 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: RESOURCE_SEMAPHORE'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'RESOURCE_SEMAPHORE'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END


					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 109 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  109 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: RESOURCE_SEMAPHORE_QUERY_COMPILE'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'RESOURCE_SEMAPHORE_QUERY_COMPILE'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END


					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 121 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  121 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: Serializable Locking'  AS Finding ,
											'http://BrentOzar.com/go/serializable' AS URL ,
											CAST(SUM([wait_time_ms]) / 1000 AS VARCHAR(100)) 
											+ ' seconds of this wait have been recorded. Queries are forcing serial operation (one query at a time) with lock hints.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type LIKE '%LCK%R%'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END



						IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 111 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  DatabaseName ,
									  URL ,
									  Details
									)
									SELECT  111 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingGroup ,
											'Possibly Broken Log Shipping'  AS Finding ,
											d.[name] ,
											'http://BrentOzar.com/go/shipping' AS URL ,
											d.[name] 
											+ ' is in a restoring state, but has not had a backup applied in the last two days. This is a possible indication of a broken transaction log shipping setup.'
											FROM [master].sys.databases d
											INNER JOIN [master].sys.database_mirroring dm ON d.database_id = dm.database_id
												AND dm.mirroring_role IS NULL
											WHERE ( d.[state] = 1
											OR (d.[state] = 0 AND d.[is_in_standby] = 1) )
											AND NOT EXISTS(SELECT * FROM msdb.dbo.restorehistory rh
											INNER JOIN msdb.dbo.backupset bs ON rh.backup_set_id = bs.backup_set_id
											WHERE d.[name] COLLATE SQL_Latin1_General_CP1_CI_AS = rh.destination_database_name COLLATE SQL_Latin1_General_CP1_CI_AS
											AND rh.restore_date >= DATEADD(dd, -2, GETDATE()))

						END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 112 )
									AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'change_tracking_databases')
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT 112 AS CheckID,
							  100 AS Priority,
							  ''Performance'' AS FindingsGroup,
							  ''Change Tracking Enabled'' AS Finding,
							  ''http://BrentOzar.com/go/tracking'' AS URL,
							  ( d.[name] + '' has change tracking enabled. This is not a default setting, and it has some performance overhead. It keeps track of changes to rows in tables that have change tracking turned on.'' ) AS Details FROM sys.change_tracking_databases 
AS ctd INNER JOIN sys.databases AS d ON ctd.database_id = d.database_id';
										EXECUTE(@StringToExecute);
							END

						IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 116 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  116 AS CheckID ,
											200 AS Priority ,
											'Informational' AS FindingGroup ,
											'Backup Compression Default Off'  AS Finding ,
											'http://BrentOzar.com/go/backup' AS URL ,
											'Backup compression is included with SQL Server 2008R2 & newer, even in Standard Edition. We recommend turning backup compression on by default so that ad-hoc backups will get compressed.'
											FROM sys.configurations
											WHERE configuration_id = 1579 AND CAST(value_in_use AS INT) = 0

						END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 117 )
									AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'dm_exec_query_resource_semaphores')
							BEGIN
								SET @StringToExecute = 'IF 0 < (SELECT SUM([forced_grant_count]) FROM sys.dm_exec_query_resource_semaphores WHERE [forced_grant_count] IS NOT NULL)
								INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT 117 AS CheckID,
							  100 AS Priority,
							  ''Performance'' AS FindingsGroup,
							  ''Memory Pressure Affecting Queries'' AS Finding,
							  ''http://BrentOzar.com/go/grants'' AS URL,
							  CAST(SUM(forced_grant_count) AS NVARCHAR(100)) + '' forced grants reported in the DMV sys.dm_exec_query_resource_semaphores, indicating memory pressure has affected query runtimes.''
							  FROM sys.dm_exec_query_resource_semaphores WHERE [forced_grant_count] IS NOT NULL;'
										EXECUTE(@StringToExecute);
							END



						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 124 )
							BEGIN
								INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
								SELECT 124, 100, 'Performance', 'Deadlocks Happening Daily', 'http://BrentOzar.com/go/deadlocks',
									CAST(p.cntr_value AS NVARCHAR(100)) + ' deadlocks have been recorded since startup.' AS Details
								FROM sys.dm_os_performance_counters p
									INNER JOIN sys.databases d ON d.name = 'tempdb'
								WHERE RTRIM(p.counter_name) = 'Number of Deadlocks/sec'
									AND RTRIM(p.instance_name) = '_Total'
									AND p.cntr_value > 0
									AND (1.0 * p.cntr_value / NULLIF(datediff(DD,create_date,CURRENT_TIMESTAMP),0)) > 10;
							END


						IF DATEADD(mi, -15, GETDATE()) < (SELECT TOP 1 creation_time FROM sys.dm_exec_query_stats ORDER BY creation_time)
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								FindingsGroup,
								Finding,
								URL,
								Details)
							SELECT TOP 1 125, 10, 'Performance', 'Plan Cache Erased Recently', 'http://BrentOzar.com/askbrent/plan-cache-erased-recently/',
								'The oldest query in the plan cache was created at ' + CAST(creation_time AS NVARCHAR(50)) 
								+ '. Someone ran DBCC FREEPROCCACHE, restarted SQL Server, or it is under horrific memory pressure.'
							FROM sys.dm_exec_query_stats WITH (NOLOCK)
							ORDER BY creation_time	
						END;

						IF EXISTS (SELECT * FROM sys.configurations WHERE name = 'priority boost' AND (value = 1 OR value_in_use = 1))
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								FindingsGroup,
								Finding,
								URL,
								Details)
							VALUES(126, 5, 'Reliability', 'Priority Boost Enabled', 'http://BrentOzar.com/go/priorityboost/',
								'Priority Boost sounds awesome, but it can actually cause your SQL Server to crash.')
						END;

						IF EXISTS (select * from msdb.dbo.backupset WHERE database_name = 'ReportServerTempDB')
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								DatabaseName,
								FindingsGroup,
								Finding,
								URL,
								Details)
							VALUES(127, 200, 'ReportServerTempDB', 'Backup', 'Backing Up Unneeded Database', 'http://BrentOzar.com/go/reportservertempdb/',
								'This database is being backed up, but you probably do not need to. See the URL for more details on how to reconstruct it.')
						END;

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 128 )
							BEGIN

							IF (@ProductVersionMajor = 12 AND @ProductVersionMinor < 2000) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor <= 2100) OR
							   (@ProductVersionMajor = 10.5 AND @ProductVersionMinor <= 2500) OR
							   (@ProductVersionMajor = 10 AND @ProductVersionMinor <= 4000) OR
							   (@ProductVersionMajor = 9 AND @ProductVersionMinor <= 5000)
								BEGIN
								INSERT INTO #BlitzResults(CheckID, Priority, FindingsGroup, Finding, URL, Details)
									VALUES(128, 20, 'Reliability', 'Unsupported Build of SQL Server', 'http://BrentOzar.com/go/unsupported',
										'Version ' + CAST(@ProductVersionMajor AS VARCHAR(100)) 
										+ '.' + CAST(@ProductVersionMinor AS VARCHAR(100)) + ' is no longer supported by Microsoft. You need to apply a service pack.');
								END;

							END;

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 129 )
							BEGIN
							IF (@ProductVersionMajor = 11 AND @ProductVersionMinor >= 3000 AND @ProductVersionMinor <= 3436) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor = 5058) OR
							   (@ProductVersionMajor = 12 AND @ProductVersionMinor >= 2000 AND @ProductVersionMinor <= 2342)
								BEGIN
								INSERT INTO #BlitzResults(CheckID, Priority, FindingsGroup, Finding, URL, Details)
									VALUES(129, 20, 'Reliability', 'Dangerous Build of SQL Server', 'http://sqlperformance.com/2014/06/sql-indexes/hotfix-sql-2012-rebuilds',
										'There are dangerous known bugs with version ' 
										+ CAST(@ProductVersionMajor AS VARCHAR(100)) + '.' + CAST(@ProductVersionMinor AS VARCHAR(100)) + '. Check the URL for details and apply the right service pack or hotfix.');
								END;

							END;



                        /* Performance - High Memory Use for In-Memory OLTP (Hekaton) */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 145 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_db_xtp_table_memory_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 145 AS CheckID,
			                        10 AS Priority,
			                        ''Performance'' AS FindingsGroup,
			                        ''High Memory Use for In-Memory OLTP (Hekaton)'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        CAST(CAST((SUM(mem.pages_kb / 1024.0) / CAST(value_in_use AS INT) * 100) AS INT) AS NVARCHAR(100)) + ''% of your ''
									 + CAST(CAST((CAST(value_in_use AS DECIMAL(38,1)) / 1024) AS MONEY) AS NVARCHAR(100)) + ''GB of your max server m
emory is being used for in-memory OLTP tables (Hekaton). Microsoft recommends having 2X your Hekaton table space available in memory just for Hekaton, with a max of 250GB of in-memory data regardless of your server memory capacity.'' AS Details
			                        FROM sys.configurations c INNER JOIN sys.dm_os_memory_clerks mem ON mem.type = ''MEMORYCLERK_XTP''
                                    WHERE c.name = ''max server memory (MB)''
                                    GROUP BY c.value_in_use
                                    HAVING CAST(value_in_use AS DECIMAL(38,2)) * .25 < SUM(mem.pages_kb / 1024.0)
                                      OR SUM(mem.pages_kb / 1024.0) > 250000';
		                        EXECUTE(@StringToExecute);
	                        END


                        /* Performance - In-Memory OLTP (Hekaton) In Use */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 146 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_db_xtp_table_memory_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 146 AS CheckID,
			                        200 AS Priority,
			                        ''Performance'' AS FindingsGroup,
			                        ''In-Memory OLTP (Hekaton) In Use'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        CAST(CAST((SUM(mem.pages_kb / 1024.0) / CAST(value_in_use AS INT) * 100) AS INT) AS NVARCHAR(100)) 
									+ ''% of your '' + CAST(CAST((CAST(value_in_use AS DECIMAL(38,1)) / 1024) AS MONEY) AS NVARCHAR(100)) + ''GB of your max server m
emory is being used for in-memory OLTP tables (Hekaton).'' AS Details
			                        FROM sys.configurations c INNER JOIN sys.dm_os_memory_clerks mem ON mem.type = ''MEMORYCLERK_XTP''
                                    WHERE c.name = ''max server memory (MB)''
                                    GROUP BY c.value_in_use
                                    HAVING SUM(mem.pages_kb / 1024.0) > 10';
		       EXECUTE(@StringToExecute);
	                        END

                        /* In-Memory OLTP (Hekaton) - Transaction Errors */
                        IF NOT EXISTS ( SELECT  1
				   FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 147 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_xtp_transaction_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 147 AS CheckID,
			                        100 AS Priority,
			                        ''In-Memory OLTP (Hekaton)'' AS FindingsGroup,
			                        ''Transaction Errors'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        ''Since restart: '' + CAST(validation_failures AS NVARCHAR(100)) + '' validation failures, '' 
									+ CAST(dependencies_failed AS NVARCHAR(100)) + '' dependency failures, '' + CAST(write_conflicts AS NVARCHAR(100)) + '' write conflic
ts, '' + CAST(unique_constraint_violations AS NVARCHAR(100)) + '' unique constraint violations.'' AS Details
			                        FROM sys.dm_xtp_transaction_stats
                                    WHERE validation_failures <> 0
                                            OR dependencies_failed <> 0
                                            OR write_conflicts <> 0
                                            OR unique_constraint_violations <> 0;'
		                        EXECUTE(@StringToExecute);
	                        END



                        /* Reliability - Database Files on Network File Shares */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 148 )
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 148 AS CheckID ,
						                        d.[name] AS DatabaseName ,
						                        50 AS Priority ,
						                        'Reliability' AS FindingsGroup ,
						                        'Database Files on Network File Shares' AS Finding ,
						                        'http://BrentOzar.com/go/nas' AS URL ,
						                        ( 'Files for this database are on: ' + LEFT(mf.physical_name, 30)) AS Details
				                        FROM    sys.databases d
                                          INNER JOIN sys.master_files mf ON d.database_id = mf.database_id
				                        WHERE mf.physical_name LIKE '\\%'
						                        AND d.name NOT IN ( SELECT DISTINCT
													                        DatabaseName
											                        FROM    #SkipChecks )
	                        END

                        /* Reliability - Database Files Stored in Azure */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 149 )
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                      )
				                        SELECT DISTINCT 149 AS CheckID ,
						                        d.[name] AS DatabaseName ,
						                        50 AS Priority ,
						           'Reliability' AS FindingsGroup ,
						                        'Database Files Stored in Azure' AS Finding ,
						                        'http://BrentOzar.com/go/azurefiles' AS URL ,
						                        ( 'Files for this database are on: ' + LEFT(mf.physical_name, 30)) AS Details
				                        FROM    sys.databases d
                                          INNER JOIN sys.master_files mf ON d.database_id = mf.database_id
				                        WHERE mf.physical_name LIKE 'http://%'
						                        AND d.name NOT IN ( SELECT DISTINCT
													                        DatabaseName
											                        FROM    #SkipChecks )
	                        END


                        /* Reliability - Errors Logged Recently in the Default Trace */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 150 )
	                        BEGIN

		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 150 AS CheckID ,
					                            t.DatabaseName,
						                        50 AS Priority ,
						                        'Reliability' AS FindingsGroup ,
						                        'Errors Logged Recently in the Default Trace' AS Finding ,
						                        'http://BrentOzar.com/go/defaulttrace' AS URL ,
						                         CAST(t.TextData AS NVARCHAR(4000)) AS Details
                                        FROM    sys.fn_trace_gettable(@path, DEFAULT) t
                                        WHERE t.EventClass = 22
                                          AND t.Severity >= 17
                                          AND t.StartTime > DATEADD(dd, -30, GETDATE())
	                        END


                        /* Performance - Log File Growths Slow */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 151 )
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 151 AS CheckID ,
					                            t.DatabaseName,
						                        50 AS Priority ,
						                        'Performance' AS FindingsGroup ,
						                        'Log File Growths Slow' AS Finding ,
						                        'http://BrentOzar.com/go/filegrowth' AS URL ,
						                        CAST(COUNT(*) AS NVARCHAR(100)) + ' growths took more than 15 seconds each. Consider setting log file autogrowth to a smaller increment.' AS Details
                                        FROM    sys.fn_trace_gettable(@path, DEFAULT) t
                                        WHERE t.EventClass = 93
                                          AND t.StartTime > DATEADD(dd, -30, GETDATE())
                                          AND t.Duration > 1 --15000000
                                        GROUP BY t.DatabaseName
                                        HAVING COUNT(*) > 1
	                        END

						/* Populate a list of database defaults. I'm doing this kind of oddly -
						    it reads like a lot of work, but this way it compiles & runs on all
						    versions of SQL Server.
						*/
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_supplemental_logging_enabled', 0, 131, 210, 'Supplemental Logging Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_supplemental_logging_enabled' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'snapshot_isolation_state', 0, 132, 210, 'Snapshot Isolation Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'snapshot_isolation_state' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_read_committed_snapshot_on', 0, 133, 210, 'Read Committed Snapshot Isolation Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_read_committed_snapshot_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_auto_create_stats_incremental_on', 0, 134, 210, 'Auto Create Stats Incremental Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_auto_create_stats_incremental_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_ansi_null_default_on', 0, 135, 210, 'ANSI NULL Default Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_ansi_null_default_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_recursive_triggers_on', 0, 136, 210, 'Recursive Triggers Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_recursive_triggers_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_trustworthy_on', 0, 137, 210, 'Trustworthy Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_trustworthy_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_parameterization_forced', 0, 138, 210, 'Forced Parameterization Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_parameterization_forced' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_query_store_on', 0, 139, 210, 'Query Store Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_query_store_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_cdc_enabled', 0, 140, 210, 'Change Data Capture Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_cdc_enabled' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'containment', 0, 141, 210, 'Containment Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'containment' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'target_recovery_time_in_seconds', 0, 142, 210, 'Target Recovery Time Changed', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'target_recovery_time_in_seconds' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'delayed_durability', 0, 143, 210, 'Delayed Durability Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'delayed_durability' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_memory_optimized_elevate_to_snapshot_on', 0, 144, 210, 'Memory Optimized Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_memory_optimized_elevate_to_snapshot_on' AND object_id = OBJECT_ID('sys.databases');

						DECLARE DatabaseDefaultsLoop CURSOR FOR
						  SELECT name, DefaultValue, CheckID, Priority, Finding, URL, Details
						  FROM #DatabaseDefaults

						OPEN DatabaseDefaultsLoop
						FETCH NEXT FROM DatabaseDefaultsLoop into @CurrentName, @CurrentDefaultValue, @CurrentCheckID, @CurrentPriority, @CurrentFinding, @CurrentURL, @CurrentDetails
						WHILE @@FETCH_STATUS = 0
						BEGIN 

						    SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details)
						       SELECT ' + CAST(@CurrentCheckID AS NVARCHAR(200)) + ', d.[name], ' + CAST(@CurrentPriority AS NVARCHAR(200)) 
							   + ', ''Non-Default Database Config'', ''' + @CurrentFinding + ''',''' + @CurrentURL + ''',''' + COALESCE(@CurrentDetails, 'This database setting is not the default.') 
							   + '''
						        FROM sys.databases d
						        WHERE d.database_id > 4 AND (d.[' + @CurrentName + '] <> ' + @CurrentDefaultValue + ' OR d.[' + @CurrentName + '] IS NULL);';
						    EXEC (@StringToExecute);

						FETCH NEXT FROM DatabaseDefaultsLoop into @CurrentName, @CurrentDefaultValue, @CurrentCheckID, @CurrentPriority, @CurrentFinding, @CurrentURL, @CurrentDetails 
						END

						CLOSE DatabaseDefaultsLoop
						DEALLOCATE DatabaseDefaultsLoop;
							
				IF @CheckUserDatabaseObjects = 1
					BEGIN

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 32 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
			SELECT DISTINCT 32,
			''?'',
			110,
			''Performance'',
			''Triggers on Tables'',
			''http://BrentOzar.com/go/trig'',
			(''The ['' + DB_NAME() + ''] database has triggers on the '' + s.name + ''.'' + o.name + '' table.'')
			FROM [?].sys.triggers t INNER JOIN [?].sys.objects o ON t.parent_id = o.object_id
			INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE t.is_ms_shipped = 0 AND DB_NAME() != ''ReportServer''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 38 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
		  SELECT DISTINCT 38,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Active Tables Without Clustered Indexes'',
		  ''http://BrentOzar.com/go/heaps'',
		  (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that are being actively queried.'')
		  FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id
		  INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		  INNER JOIN sys.databases sd ON sd.name = ''?''
		  LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id
		  WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NOT NULL
		  AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 39 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
		  SELECT DISTINCT 39,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Inactive Tables Without Clustered Indexes'',
		  ''http://BrentOzar.com/go/heaps'',
		  (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that have not been queried since the last restart.  These may be backup tables carelessly left behind.'')
		  FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id
		  INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		  INNER JOIN sys.databases sd ON sd.name = ''?''
		  LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id
		  WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NULL
		  AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 46 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 46,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Leftover Fake Indexes From Wizards'',
		  ''http://BrentOzar.com/go/hypo'',
		  (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is a leftover hypothetical index from the Index Tuning Wizard or Database Tuning Advisor.  This index is not actually helping performance and should be remove
d.'')
		  from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_hypothetical = 1';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 47 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 47,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Indexes Disabled'',
		  ''http://BrentOzar.com/go/ixoff'',
		  (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is disabled.  This index is not actually helping performance and should either be enabled or removed.'')
		  from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_disabled = 1';
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 48 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT 48,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Foreign Keys Not Trusted'',
		  ''http://BrentOzar.com/go/trust'',
		  (''The ['' + DB_NAME() + ''] database has foreign keys that were probably disabled, data was changed, and then the key was enabled again.  Simply enabling the key is not enough for the optimizer to use this key - we have to alter the table using the W
ITH CHECK CHECK CONSTRAINT parameter.'')
		  from [?].sys.foreign_keys i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 56 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 56,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Check Constraint Not Trusted'',
		  ''http://BrentOzar.com/go/trust'',
		  (''The check constraint ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is not trusted - meaning, it was disabled, data was changed, and then the constraint was enabled again.  Simply enabling the constraint is not enou
gh for the optimizer to use this constraint - we have to alter the table using the WITH CHECK CHECK CONSTRAINT parameter.'')
		  from [?].sys.check_constraints i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id
		  INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 95 )
							BEGIN
								IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
									AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
									BEGIN
										EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
				  (CheckID,
				  DatabaseName,
				  Priority,
				  FindingsGroup,
				  Finding,
				  URL,
				  Details)
			SELECT TOP 1 95 AS CheckID,
			''?'' as DatabaseName,
			110 AS Priority,
			''Performance'' AS FindingsGroup,
			''Plan Guides Enabled'' AS Finding,
			''http://BrentOzar.com/go/guides'' AS URL,
			(''Database ['' + DB_NAME() + ''] has query plan guides so a query will always get a specific execution plan. If you are having trouble getting query performance to improve, it might be due to a frozen plan. Review the DMV sys.plan_guides to learn more
 about the plan guides in place on this server.'') AS Details
			FROM [?].sys.plan_guides WHERE is_disabled = 0'
									END;
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 60 )
							BEGIN
								EXEC sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT  DISTINCT 60 AS CheckID,
		  ''?'' as DatabaseName,
		  100 AS Priority,
		  ''Performance'' AS FindingsGroup,
		  ''Fill Factor Changed'',
		  ''http://brentozar.com/go/fillfactor'' AS URL,
		  ''The ['' + DB_NAME() + ''] database has objects with fill factor < 80%. This can cause memory and storage performance problems, but may also prevent page splits.''
		  FROM    [?].sys.indexes
		  WHERE   fill_factor <> 0 AND fill_factor < 80 AND is_disabled = 0 AND is_hypothetical = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 78 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 78,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Stored Procedure WITH RECOMPILE'',
		  ''http://BrentOzar.com/go/recompile'',
		  (''['' + DB_NAME() + ''].['' + SPECIFIC_SCHEMA + ''].['' + SPECIFIC_NAME + ''] has WITH RECOMPILE in the stored procedure code, which may cause increased CPU usage due to constant recompiles of the code.'')
		  from [?].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_DEFINITION LIKE N''%WITH RECOMPILE%'' AND SPECIFIC_NAME NOT LIKE ''sp_Blitz%%'';';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 86 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 86, DB_NAME(),
								 20, ''Security'', ''Elevated Permissions on a Database'', ''http://BrentOzar.com/go/elevated'', (''In ['' + DB_NAME() + ''], 
								 user ['' + u.name + '']  has the role ['' + g.name + ''].  This user can perform tasks beyond just reading and writing data.'') FROM [?].dbo.sysmembers m inner join   [?].dbo.sysusers u on m.memberuid = u.uid inner join sysusers g on m.groupuid =
 g.uid 
								 where u.name <> ''dbo'' and g.name in (''db_owner'' , ''db_accessAdmin'' , ''db_securityadmin'' , ''db_ddladmin'')';
							END


							/*Check for non-aligned indexes in partioned databases*/

										IF NOT EXISTS ( SELECT  1
														FROM    #SkipChecks
														WHERE   DatabaseName IS NULL AND CheckID = 72 )
											BEGIN
												EXEC dbo.sp_MSforeachdb 'USE [?];
								insert into #partdb(dbname, objectname, type_desc)
								SELECT distinct db_name(DB_ID()) as DBName,o.name Object_Name,ds.type_desc
								FROM sys.objects AS o JOIN sys.indexes AS i ON o.object_id = i.object_id
								JOIN sys.data_spaces ds on ds.data_space_id = i.data_space_id
								LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s ON i.object_id = s.object_id AND i.index_id = s.index_id AND s.database_id = DB_ID()
								WHERE  o.type = ''u''
								 -- Clustered and Non-Clustered indexes
								AND i.type IN (1, 2)
								AND o.object_id in
								  (
									SELECT a.object_id from
									  (SELECT ob.object_id, ds.type_desc from sys.objects ob JOIN sys.indexes ind on ind.object_id = ob.object_id join sys.data_spaces ds on ds.data_space_id = ind.data_space_id
									  GROUP BY ob.object_id, ds.type_desc ) a group by a.object_id having COUNT (*) > 1
								  )'
												INSERT  INTO #BlitzResults
														( CheckID ,
														  DatabaseName ,
														  Priority ,
														  FindingsGroup ,
														  Finding ,
														  URL ,
														  Details
														)
														SELECT DISTINCT
																72 AS CheckID ,
																dbname AS DatabaseName ,
																100 AS Priority ,
																'Performance' AS FindingsGroup ,
																'The partitioned database ' + dbname
																+ ' may have non-aligned indexes' AS Finding ,
																'http://BrentOzar.com/go/aligned' AS URL ,
																'Having non-aligned indexes on partitioned tables may cause inefficient query plans and CPU pressure' AS Details
														FROM    #partdb
														WHERE   dbname IS NOT NULL
																AND dbname NOT IN ( SELECT DISTINCT
																						  DatabaseName
																					FROM  #SkipChecks )
												DROP TABLE #partdb
											END


											IF NOT EXISTS ( SELECT  1
															FROM    #SkipChecks
															WHERE   DatabaseName IS NULL AND CheckID = 113 )
												BEGIN
													EXEC dbo.sp_MSforeachdb 'USE [?];
							  INSERT INTO #BlitzResults
									(CheckID,
									DatabaseName,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT DISTINCT 113,
							  ''?'',
							  50,
							  ''Reliability'',
							  ''Full Text Indexes Not Updating'',
							  ''http://BrentOzar.com/go/fulltext'',
							  (''At least one full text index in this database has not been crawled in the last week.'')
							  from [?].sys.fulltext_indexes i WHERE i.is_enabled = 1 AND i.crawl_end_date < DATEADD(dd, -7, GETDATE())';
												END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 115 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 115,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Parallelism Rocket Surgery'',
		  ''http://BrentOzar.com/go/makeparallel'',
		  (''['' + DB_NAME() + ''] has a make_parallel function, indicating that an advanced developer may be manhandling SQL Server into forcing queries to go parallel.'')
		  from [?].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''make_parallel'' AND ROUTINE_TYPE = ''FUNCTION''';
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 122 )
							BEGIN
								/* SQL Server 2012 and newer uses temporary stats for AlwaysOn Availability Groups, and those show up as user-created */
								IF EXISTS (SELECT *
									  FROM sys.all_columns c
									  INNER JOIN sys.all_objects o ON c.object_id = o.object_id
									  WHERE c.name = 'is_temporary' AND o.name = 'stats')

										EXEC dbo.sp_MSforeachdb 'USE [?];
												INSERT INTO #BlitzResults
													(CheckID,
													DatabaseName,
													Priority,
													FindingsGroup,
													Finding,
													URL,
													Details)
												SELECT TOP 1 122,
												''?'',
												200,
												''Performance'',
												''User-Created Statistics In Place'',
												''http://BrentOzar.com/go/userstats'',
												(''['' + DB_NAME() + ''] has user-created statistics. This indicates that someone is being a rocket scientist with the stats, and might actually be slowing things down, especially during stats updates.'')
												from [?].sys.stats WHERE user_created = 1 AND is_temporary = 0';

									ELSE
										EXEC dbo.sp_MSforeachdb 'USE [?];
												INSERT INTO #BlitzResults
													(CheckID,
													DatabaseName,
													Priority,
													FindingsGroup,
													Finding,
													URL,
													Details)
												SELECT TOP 1 122,
												''?'',
												200,
												''Performance'',
												''User-Created Statistics In Place'',
												''http://BrentOzar.com/go/userstats'',
												(''['' + DB_NAME() + ''] has user-created statistics. This indicates that someone is being a rocket scientist with the stats, and might actually be slowing things down, especially during stats updates.'')
												from [?].sys.stats WHERE user_created = 1';


							END /* IF NOT EXISTS ( SELECT  1 */


					END /* IF @CheckUserDatabaseObjects = 1 */

				IF @CheckProcedureCache = 1
					BEGIN

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 35 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  35 AS CheckID ,
												100 AS Priority ,
												'Performance' AS FindingsGroup ,
												'Single-Use Plans in Procedure Cache' AS Finding ,
												'http://BrentOzar.com/go/single' AS URL ,
												( CAST(COUNT(*) AS VARCHAR(10))
												  + ' query plans are taking up memory in the procedure cache. This may be wasted memory if we cache plans for queries that never get called again. This may be a good use case for SQL Server 2008''s Optimize for Ad Hoc or for Forced Parameteri
zation.' ) AS Details
										FROM    sys.dm_exec_cached_plans AS cp
										WHERE   cp.usecounts = 1
												AND cp.objtype = 'Adhoc'
												AND EXISTS ( SELECT
																  1
															 FROM sys.configurations
															 WHERE
																  name = 'optimize for ad hoc workloads'
																  AND value_in_use = 0 )
										HAVING  COUNT(*) > 1;
							END


		  /* Set up the cache tables. Different on 2005 since it doesn't support query_hash, query_plan_hash. */
						IF @@VERSION LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								IF @CheckProcedureCacheFilter = 'CPU'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
										[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],
										[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],
										[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],
										[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
										 AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
										 qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time]
										 ,qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],
										 qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
										 qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],
										 qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			  FROM sys.dm_exec_query_stats qs
			  ORDER BY qs.total_worker_time DESC)
			  
			  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],
			  [execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],
			  [min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],
			  [total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],
			  [max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
			  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],
			  qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],
			  qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],
			  qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			  FROM queries qs
			  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle 
			  AND qs.statement_start_offset = qsCaught.statement_start_offset
			  WHERE qsCaught.sql_handle IS NULL;'

										EXECUTE(@StringToExecute)

							
									END

								IF @CheckProcedureCacheFilter = 'Reads'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
										[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],
										[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],
										[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],
										[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time]),
					AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
					qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],
					qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],
					qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],
					qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_logical_reads DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],
		  [execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],
		  [max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],
		  [min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],
		  [max_elapsed_time])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],
		  qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],
			qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle 
		  AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'

										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'ExecCount'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[las
t_logical_writes],[min_logical_writes],
[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],
		  qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],
		  qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],
		  qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.execution_count DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],
		  [execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],
[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],
[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],
		  qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],
		  qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],
		  qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Duration'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],
										[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],
										[min_logical_writes][max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],
										[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
			qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],
			qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],
			qs.[max_logical_writes],qs[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],
			qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			FROM sys.dm_exec_query_stats qs
			ORDER BY qs.total_elapsed_time DESC)
			INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_wor
ker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],
			[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],
			[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],
			[min_elapsed_time],[max_elapsed_time])
			SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
			qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],
			qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],
			qs.[min_logical_writes],qs[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],
			qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			FROM queries qs
			LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle 
			AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
			WHERE qsCaught.sql_handle IS NULL;'


										EXECUTE(@StringToExecute)
									END

							END;
						IF @@VERSION LIKE '%Microsoft SQL Server 2008%'
							OR @@VERSION LIKE '%Microsoft SQL Server 2012%'
							OR @@VERSION LIKE '%Microsoft SQL Server 2014%'
							BEGIN
								IF @CheckProcedureCacheFilter = 'CPU'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[las
t_logical_writes],
[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_el
apsed_time],[query_hash],[query_plan_hash])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
		  qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],
		  qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],
		  qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],
		  qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_worker_time DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
		  [last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],
		  [max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_rea
ds],[max_logical_reads],[total_clr_time],[last_clr_time],
		  [min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],
		  qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total
_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],
		  qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle 
		  AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'



										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Reads'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],
										[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes]
										,[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],
										[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],
										[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
		  qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],
		  qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],
		  qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],
		  qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_logical_reads DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
		  [last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],
		  [min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],
[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],
[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],
[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],
		  qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],
		  qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle 
		  AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'

										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'ExecCount'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
					SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],
										[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes]
										,[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],
										[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],
										[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
		  qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],
		  qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],
		  qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],
		  qs.[query_plan_hash]
		    FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.execution_count DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
		  [last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],
		  [min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],
[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],
[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],
[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],
		  qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],
		  qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle 
		  AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'


										EXECUTE(@StringToExecute)
									END
	
								IF @CheckProcedureCacheFilter = 'Duration'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],
										[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],
										[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes]
										,[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],
										[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],
										[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],
		  qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],
		  qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],
		  qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],
		  qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_elapsed_time DESC)
		    INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],
		  [last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],
		  [min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],
[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],
[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],
[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],
		  qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],
		  qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],
		  qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],
		  qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],
		  qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle 
		  AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'


										EXECUTE(@StringToExecute)
									END

	
		/* Populate the query_plan_filtered field. Only works in 2005SP2+, but we're just doing it in 2008 to be safe. */
								UPDATE  #dm_exec_query_stats
								SET     query_plan_filtered = qp.query_plan
								FROM    #dm_exec_query_stats qs
										CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle,
																  qs.statement_start_offset,
																  qs.statement_end_offset)
										AS qp

							END;


		/* Populate the additional query_plan, text, and text_filtered fields */
						UPDATE  #dm_exec_query_stats
						SET     query_plan = qp.query_plan ,
								[text] = st.[text] ,
								text_filtered = SUBSTRING(st.text,
														  ( qs.statement_start_offset
															/ 2 ) + 1,
														  ( ( CASE qs.statement_end_offset
																WHEN -1
																THEN DATALENGTH(st.text)
																ELSE qs.statement_end_offset
															  END
															  - qs.statement_start_offset )
															/ 2 ) + 1), 
									database_name = db_name(st.dbid), 
									object_name = object_name(st.objectid, st.dbid)
						FROM    #dm_exec_query_stats qs
								CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
								CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)
								AS qp

		/* Dump instances of our own script. We're not trying to tune ourselves. */
						DELETE  #dm_exec_query_stats
						WHERE   text LIKE '%sp_Blitz%'
								OR text LIKE '%#BlitzResults%'



		/* Look for implicit conversions */

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 63 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered, 
										  DatabaseName, 
										  [ObjectName]
										)
										SELECT  63 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Implicit Conversion' AS Finding ,
												'http://BrentOzar.com/go/implicit' AS URL ,
												( 'One of the top resource-intensive queries is comparing two fields that are not the same datatype.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
												,qs.database_name, qs.object_name
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%CONVERT_IMPLICIT%'
												AND COALESCE(qs.query_plan_filtered,
															 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%PhysicalOp="Index Scan"%'

							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 64 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered,
										  DatabaseName, 
										    [ObjectName]
										  
										)
										SELECT  64 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Implicit Conversion Affecting Cardinality' AS Finding ,
												'http://BrentOzar.com/go/implicit' AS URL ,
												( 'One of the top resource-intensive queries has an implicit conversion that is affecting cardinality estimation.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
												,qs.database_name, qs.object_name
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<PlanAffectingConvert ConvertIssue="Cardinality Estimate" Expression="CONVERT_IMPLICIT%'
							END

							/* @cms4j, 29.11.2013: Look for RID or Key Lookups */
							IF NOT EXISTS ( SELECT  1
											FROM    #SkipChecks
											WHERE   DatabaseName IS NULL AND CheckID = 118 )
								BEGIN
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details ,
											  QueryPlan ,
											  QueryPlanFiltered, 
										  DatabaseName, 
										  [ObjectName]
											)
											SELECT  118 AS CheckID ,
													120 AS Priority ,
													'Query Plans' AS FindingsGroup ,
													'RID or Key Lookups' AS Finding ,
													'http://BrentOzar.com/go/lookup' AS URL ,
													'One of the top resource-intensive queries contains RID or Key Lookups. Try to avoid them by creating covering indexes.' AS Details ,
													qs.query_plan ,
													qs.query_plan_filtered
												,qs.database_name, qs.object_name
											FROM    #dm_exec_query_stats qs
											WHERE   COALESCE(qs.query_plan_filtered,
															 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%Lookup="1"%'
								END /* @cms4j, 29.11.2013: Look for RID or Key Lookups */


						/* Look for missing indexes */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 65 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered, 
										  DatabaseName, 
										    [ObjectName]
										)
										SELECT  65 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Missing Index' AS Finding ,
												'http://BrentOzar.com/go/missingindex' AS URL ,
												( 'One of the top resource-intensive queries may be dramatically improved by adding an index.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
												,qs.database_name, qs.object_name
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%MissingIndexGroup%'
							END

						/* Look for cursors */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 66 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered,
										  DatabaseName, 
										    [ObjectName]
										)
										SELECT  66 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Cursor' AS Finding ,
												'http://BrentOzar.com/go/cursor' AS URL ,
												( 'One of the top resource-intensive queries is using a cursor.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
												,qs.database_name, qs.object_name
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<StmtCursor%'
							END

		/* Look for scalar user-defined functions */

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 67 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered, 
										  DatabaseName, 
										    [ObjectName]
										)
										SELECT  67 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Scalar UDFs' AS Finding ,
												'http://BrentOzar.com/go/functions' AS URL ,
												( 'One of the top resource-intensive queries is using a user-defined scalar function that may inhibit parallelism.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
												,qs.database_name, qs.object_name
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<UserDefinedFunction%'
							END

					END /* IF @CheckProcedureCache = 1 */

		/*Check for the last good DBCC CHECKDB date */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 68 )
					BEGIN
						EXEC sp_MSforeachdb N'USE [?];
		INSERT #DBCCs
			(ParentObject,
			Object,
			Field,
			Value)
		EXEC (''DBCC DBInfo() With TableResults, NO_INFOMSGS'');
		UPDATE #DBCCs SET DbName = N''?'' WHERE DbName IS NULL;';

						WITH    DB2
								  AS ( SELECT DISTINCT
												Field ,
												Value ,
												DbName
									   FROM     #DBCCs
									   WHERE    Field = 'dbi_dbccLastKnownGood'
									 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  DatabaseName ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  68 AS CheckID ,
											DB2.DbName AS DatabaseName ,
											50 AS PRIORITY ,
											'Reliability' AS FindingsGroup ,
											'Last good DBCC CHECKDB over 2 weeks old' AS Finding ,
											'http://BrentOzar.com/go/checkdb' AS URL ,
											'Database [' + DB2.DbName + ']'
											+ CASE DB2.Value
												WHEN '1900-01-01 00:00:00.000'
												THEN ' never had a successful DBCC CHECKDB.'
												ELSE ' last had a successful DBCC CHECKDB run on '
													 + DB2.Value + '.'
											  END
											+ ' This check should be run regularly to catch any database corruption as soon as possible.'
											+ ' Note: you can restore a backup of a busy production database to a test server and run DBCC CHECKDB '
											+ ' against that to minimize impact. If you do that, you can ignore this warning.' AS Details
									FROM    DB2
									WHERE   DB2.DbName NOT IN ( SELECT DISTINCT
																  DatabaseName
																FROM
																  #SkipChecks )
											AND CONVERT(DATETIME, DB2.Value, 121) < DATEADD(DD,
																  -14,
																  CURRENT_TIMESTAMP)
					END

		/*Check for high VLF count: this will omit any database snapshots*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 69 )
					BEGIN
						IF @@VERSION LIKE 'Microsoft SQL Server 2012%' OR @@VERSION LIKE 'Microsoft SQL Server 2014%'
							BEGIN
								EXEC sp_MSforeachdb N'USE [?];
		  INSERT INTO #LogInfo2012
		  EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';
		  IF    @@ROWCOUNT > 999
		  BEGIN
			INSERT  INTO #BlitzResults
			( CheckID
			,DatabaseName
			,Priority
			,FindingsGroup
			,Finding
			,URL
			,Details)
			SELECT      69
			,DB_NAME()
			,100
			,''Performance''
			,''High VLF Count''
			,''http://BrentOzar.com/go/vlf''
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) + '' virtual log files (VLFs). This may be slowing down startup, 
			restores, and even inserts/updates/deletes.''
			FROM #LogInfo2012
			WHERE EXISTS (SELECT name FROM master.sys.databases
					WHERE source_database_id is null) ;
		  END
		TRUNCATE TABLE #LogInfo2012;'
								DROP TABLE #LogInfo2012;
							END
						ELSE
							BEGIN
								EXEC sp_MSforeachdb N'USE [?];
		  INSERT INTO #LogInfo
		  EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';
		  IF    @@ROWCOUNT > 999
		  BEGIN
			INSERT  INTO #BlitzResults
			( CheckID
			,DatabaseName
			,Priority
			,FindingsGroup
			,Finding
			,URL
			,Details)
			SELECT      69
			,DB_NAME()
			,100
			,''Performance''
			,''High VLF Count''
			,''http://BrentOzar.com/go/vlf''
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) 
			+ '' virtual log files (VLFs). This may be slowing down startup, restores, and even inserts/updates/deletes.''
			FROM #LogInfo
			WHERE EXISTS (SELECT name FROM master.sys.databases
			WHERE source_database_id is null);
		  END
		  TRUNCATE TABLE #LogInfo;'
								DROP TABLE #LogInfo;
							END
					END

	/*Verify that the servername is set */
			IF NOT EXISTS ( SELECT  1
							FROM    #SkipChecks
							WHERE   DatabaseName IS NULL AND CheckID = 70 )
				BEGIN
					IF @@SERVERNAME IS NULL
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  70 AS CheckID ,
											200 AS Priority ,
											'Configuration' AS FindingsGroup ,
											'@@Servername Not Set' AS Finding ,
											'http://BrentOzar.com/go/servername' AS URL ,
											'@@Servername variable is null. You can fix it by executing: "sp_addserver ''<LocalServerName>'', local"' AS Details
						END;

					IF  /* @@SERVERNAME IS set */
						(@@SERVERNAME IS NOT NULL
						AND
						/* not a named instance */
						CHARINDEX('\',CAST(SERVERPROPERTY('ServerName') AS NVARCHAR)) = 0
						AND
						/* not clustered, when computername may be different than the servername */
						SERVERPROPERTY('IsClustered') = 0
						AND
						/* @@SERVERNAME is different than the computer name */
						@@SERVERNAME <> CAST(ISNULL(SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),@@SERVERNAME) AS NVARCHAR) )
						 BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  70 AS CheckID ,
											200 AS Priority ,
											'Configuration' AS FindingsGroup ,
											'@@Servername Not Correct' AS Finding ,
											'http://BrentOzar.com/go/servername' AS URL ,
											'The @@Servername is different than the computer name, which may trigger certificate errors.' AS Details
						END;

				END
		/*Check to see if a failsafe operator has been configured*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 73 )
					BEGIN

						DECLARE @AlertInfo TABLE
							(
							  FailSafeOperator NVARCHAR(255) ,
							  NotificationMethod INT ,
							  ForwardingServer NVARCHAR(255) ,
							  ForwardingSeverity INT ,
							  PagerToTemplate NVARCHAR(255) ,
							  PagerCCTemplate NVARCHAR(255) ,
							  PagerSubjectTemplate NVARCHAR(255) ,
							  PagerSendSubjectOnly NVARCHAR(255) ,
							  ForwardAlways INT
							)
						INSERT  INTO @AlertInfo
								EXEC [master].[dbo].[sp_MSgetalertinfo] @includeaddresses = 0
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  73 AS CheckID ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'No failsafe operator configured' AS Finding ,
										'http://BrentOzar.com/go/failsafe' AS URL ,
										( 'No failsafe operator is configured on this server.  This is a good idea just in-case there are issues with the [msdb] database that prevents alerting.' ) 
AS Details
								FROM    @AlertInfo
								WHERE   FailSafeOperator IS NULL;
					END

		/*Identify globally enabled trace flags*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 74 )
					BEGIN
						INSERT  INTO #TraceStatus
								EXEC ( ' DBCC TRACESTATUS(-1) WITH NO_INFOMSGS'
									)
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  74 AS CheckID ,
										200 AS Priority ,
										'Global Trace Flag' AS FindingsGroup ,
										'TraceFlag On' AS Finding ,
										'http://www.BrentOzar.com/go/traceflags/' AS URL ,
										'Trace flag ' + T.TraceFlag
										+ ' is enabled globally.' AS Details
								FROM    #TraceStatus T
					END

		/*Check for transaction log file larger than data file */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 75 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  75 AS CheckID ,
										DB_NAME(a.database_id) ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Transaction Log Larger than Data File' AS Finding ,
										'http://BrentOzar.com/go/biglog' AS URL ,
										'The database [' + DB_NAME(a.database_id)
										+ '] has a transaction log file larger than a data file. This may indicate that transaction log backups are not being performed or not performed often enough.' AS Details
								FROM    sys.master_files a
								WHERE   a.type = 1
										AND DB_NAME(a.database_id) NOT IN (
										SELECT DISTINCT
												DatabaseName
										FROM    #SkipChecks )
										AND a.size > 125000 /* Size is measured in pages here, so this gets us log files over 1GB. */
										AND a.size > ( SELECT   SUM(CAST(b.size AS BIGINT))
													   FROM     sys.master_files b
													   WHERE    a.database_id = b.database_id
																AND b.type = 0
													 )
										AND a.database_id IN (
										SELECT  database_id
										FROM    sys.databases
										WHERE   source_database_id IS NULL )
					END

		/*Check for collation conflicts between user databases and tempdb */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 76 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  76 AS CheckID ,
										name AS DatabaseName ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Collation is ' + collation_name AS Finding ,
										'http://BrentOzar.com/go/collate' AS URL ,
										'Collation differences between user databases and tempdb can cause conflicts especially when comparing string values' AS Details
								FROM    sys.databases
							WHERE   name NOT IN ( 'master', 'model', 'msdb')
										AND name NOT LIKE 'ReportServer%'
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
										AND collation_name <> ( SELECT
																  collation_name
																FROM
																  sys.databases
																WHERE
																  name = 'tempdb'
															  )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 77 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  77 AS CheckID ,
										dSnap.[name] AS DatabaseName ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Database Snapshot Online' AS Finding ,
										'http://BrentOzar.com/go/snapshot' AS URL ,
										'Database [' + dSnap.[name]
										+ '] is a snapshot of ['
										+ dOriginal.[name]
										+ ']. Make sure you have enough drive space to maintain the snapshot as the original database grows.' AS Details
								FROM    sys.databases dSnap
										INNER JOIN sys.databases dOriginal ON dSnap.source_database_id = dOriginal.database_id
																  AND dSnap.name NOT IN (
																  SELECT DISTINCT
																  DatabaseName
																  FROM
																  #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 79 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  79 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Shrink Database Job' AS Finding ,
										'http://BrentOzar.com/go/autoshrink' AS URL ,
										'In the [' + j.[name] + '] job, step ['
										+ step.[step_name]
										+ '] has SHRINKDATABASE or SHRINKFILE, which may be causing database fragmentation.' AS Details
								FROM    msdb.dbo.sysjobs j
										INNER JOIN msdb.dbo.sysjobsteps step ON j.job_id = step.job_id
								WHERE   step.command LIKE N'%SHRINKDATABASE%'
										OR step.command LIKE N'%SHRINKFILE%'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 80 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) 
						SELECT DISTINCT 80, DB_NAME(), 50, ''Reliability'', ''Max File Size Set'', ''http://BrentOzar.com/go/maxsize'', 
						(''The ['' + DB_NAME() + ''] database file '' + name + '' has a max file size set to '' + CAST(CAST(max_size AS BIGINT) * 8 / 1024 AS VARCHAR(100)) 
							+ ''MB. If it runs out of space, the database will stop working even though there may be drive space available.'') FROM sys.database_files
					 WHERE max_size <> 268435456 AND max_size <> -1 AND type <> 2';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 81 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  81 AS CheckID ,
										200 AS Priority ,
										'Non-Active Server Config' AS FindingsGroup ,
										cr.name AS Finding ,
										'http://www.BrentOzar.com/blitz/sp_configure/' AS URL ,
										( 'This sp_configure option isn''t running under its set value.  Its set value is '
										  + CAST(cr.[Value] AS VARCHAR(100))
										  + ' and its running value is '
										  + CAST(cr.value_in_use AS VARCHAR(100))
										  + '. When someone does a RECONFIGURE or restarts the instance, this setting will start taking effect.' ) AS Details
								FROM    sys.configurations cr
								WHERE   cr.value <> cr.value_in_use;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 123 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1 123 AS CheckID ,
										200 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Agent Jobs Starting Simultaneously' AS Finding ,
										'http://BrentOzar.com/go/busyagent/' AS URL ,
										( 'Multiple SQL Server Agent jobs are configured to start simultaneously. For detailed schedule listings, see the query in the URL.' ) AS Details
								FROM    msdb.dbo.sysjobactivity
								WHERE start_execution_date > DATEADD(dd, -14, GETDATE())
								GROUP BY start_execution_date HAVING COUNT(*) > 1;
					END


				IF @CheckServerInfo = 1
					BEGIN

					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 130 )
						BEGIN
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details
											)
											SELECT  130 AS CheckID ,
													250 AS Priority ,
													'Server Info' AS FindingsGroup ,
													'Server Name' AS Finding ,
													'http://BrentOzar.com/go/servername' AS URL ,
													@@SERVERNAME AS Details
												WHERE @@SERVERNAME IS NOT NULL;
								END;



						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 83 )
							BEGIN
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects
											WHERE   name = 'dm_server_services' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
				SELECT  83 AS CheckID ,
				250 AS Priority ,
				''Server Info'' AS FindingsGroup ,
				''Services'' AS Finding ,
				'''' AS URL ,
				N''Service: '' + servicename + N'' runs under service account '' + service_account + N''. Last startup time: '' 
				+ COALESCE(CAST(CAST(last_startup_time AS DATETIME) AS VARCHAR(50)), ''not shown.'') + ''. Startup type: '' + startup_type_desc + N'', currently '' + status_desc + ''.''
				FROM sys.dm_server_services;'
										EXECUTE(@StringToExecute);
									END
							END

			/* Check 84 - SQL Server 2012 */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 84 )
							BEGIN
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects o
													INNER JOIN sys.all_columns c ON o.object_id = c.object_id
											WHERE   o.name = 'dm_os_sys_info'
													AND c.name = 'physical_memory_kb' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			SELECT  84 AS CheckID ,
			250 AS Priority ,
			''Server Info'' AS FindingsGroup ,
			''Hardware'' AS Finding ,
			'''' AS URL ,
			''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_kb / 1024.0 / 1024), 1) AS INT) AS VARCHAR(50)) + ''GB.''
			FROM sys.dm_os_sys_info';
										EXECUTE(@StringToExecute);
									END

			/* Check 84 - SQL Server 2008 */
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects o
													INNER JOIN sys.all_columns c ON o.object_id = c.object_id
											WHERE   o.name = 'dm_os_sys_info'
													AND c.name = 'physical_memory_in_bytes' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			SELECT  84 AS CheckID ,
			250 AS Priority ,
			''Server Info'' AS FindingsGroup ,
			''Hardware'' AS Finding ,
			'''' AS URL ,
			''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_in_bytes / 1024.0 / 1024 / 1024), 1) AS INT) AS VARCHAR(50))
			 + ''GB.''
			FROM sys.dm_os_sys_info';
										EXECUTE(@StringToExecute);
									END
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 85 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  85 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'SQL Server Service' AS Finding ,
												'' AS URL ,
												N'Version: '
												+ CAST(SERVERPROPERTY('productversion') AS NVARCHAR(100))
												+ N'. Patch Level: '
												+ CAST(SERVERPROPERTY('productlevel') AS NVARCHAR(100))
												+ N'. Edition: '
												+ CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
												+ N'. AlwaysOn Enabled: '
												+ CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'),
																0) AS VARCHAR(100))
												+ N'. AlwaysOn Mgr Status: '
												+ CAST(COALESCE(SERVERPROPERTY('HadrManagerStatus'),
																0) AS VARCHAR(100))
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 88 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  88 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'SQL Server Last Restart' AS Finding ,
												'' AS URL ,
												CAST(create_date AS VARCHAR(100))
										FROM    sys.databases
										WHERE   database_id = 2
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 92 )
							BEGIN
								INSERT  INTO #driveInfo
										( drive, SIZE )
										EXEC master..xp_fixeddrives

								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  92 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'Drive ' + i.drive + ' Space' AS Finding ,
												'' AS URL ,
												CAST(i.SIZE AS VARCHAR)
												+ 'MB free on ' + i.drive
												+ ' drive' AS Details
										FROM    #driveInfo AS i
								DROP TABLE #driveInfo
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 103 )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
												INNER JOIN sys.all_columns c ON o.object_id = c.object_id
										 WHERE  o.name = 'dm_os_sys_info'
												AND c.name = 'virtual_machine_type_desc' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
									SELECT 103 AS CheckID,
									250 AS Priority,
									''Server Info'' AS FindingsGroup,
									''Virtual Server'' AS Finding,
									''http://BrentOzar.com/go/virtual'' AS URL,
									''Type: ('' + virtual_machine_type_desc + '')'' AS Details
									FROM sys.dm_os_sys_info
									WHERE virtual_machine_type <> 0';
								EXECUTE(@StringToExecute);
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 114 )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
										 WHERE  o.name = 'dm_os_memory_nodes' )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
										 INNER JOIN sys.all_columns c ON o.object_id = c.object_id
										 WHERE  o.name = 'dm_os_nodes'
                                	 		AND c.name = 'processor_group' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
										SELECT  114 AS CheckID ,
												250 AS Priority ,
												''Server Info'' AS FindingsGroup ,
												''Hardware - NUMA Config'' AS Finding ,
												'''' AS URL ,
												''Node: '' + CAST(n.node_id AS NVARCHAR(10)) + '' State: '' + node_state_desc
												+ '' Online schedulers: '' + CAST(n.online_scheduler_count AS NVARCHAR(10)) + '' Processor Group: '' + CAST(n.processor_group AS NVARCHAR(10))
												+ '' Memory node: '' + CAST(n.memory_node_id AS NVARCHAR(10)) + '' Memory VAS Reserved GB: '' 
												+ CAST(CAST((m.virtual_address_space_reserved_kb / 1024.0 / 1024) AS INT) AS NVARCHAR(100))
										FROM sys.dm_os_nodes n
										INNER JOIN sys.dm_os_memory_nodes m ON n.memory_node_id = m.memory_node_id
										WHERE n.node_state_desc NOT LIKE ''%DAC%''
										ORDER BY n.node_id'
								EXECUTE(@StringToExecute);
							END


							IF NOT EXISTS ( SELECT  1
											FROM    #SkipChecks
											WHERE   DatabaseName IS NULL AND CheckID = 106 )
											AND (select convert(int,value_in_use) from sys.configurations where name = 'default trace enabled' ) = 1
							BEGIN

								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT
												 106 AS CheckID
												,250 AS Priority
												,'Server Info' AS FindingsGroup
												,'Default Trace Contents' AS Finding
												,'http://BrentOzar.com/go/trace' AS URL
												,'The default trace holds '+cast(DATEDIFF(hour,MIN(StartTime),GETDATE())as varchar)+' hours of data'
												+' between '+cast(Min(StartTime) as varchar)+' and '+cast(GETDATE()as varchar)
												+('. The default trace files are located in: '+left( @curr_tracefilename,len(@curr_tracefilename) - @indx)
												) as Details
										FROM    ::fn_trace_gettable( @base_tracefilename, default )
										WHERE EventClass BETWEEN 65500 and 65600
							END /* CheckID 106 */



					END /* IF @CheckServerInfo = 1 */
			END /* IF ( ( SERVERPROPERTY('ServerName') NOT IN ( SELECT ServerName */


				/* Delete priorites they wanted to skip. */
				IF @IgnorePrioritiesAbove IS NOT NULL
					DELETE  #BlitzResults
					WHERE   [Priority] > @IgnorePrioritiesAbove AND CheckID <> -1;

				IF @IgnorePrioritiesBelow IS NOT NULL
					DELETE  #BlitzResults
					WHERE   [Priority] < @IgnorePrioritiesBelow AND CheckID <> -1;

				/* Delete checks they wanted to skip. */
				IF @SkipChecksTable IS NOT NULL
					BEGIN
						DELETE  FROM #BlitzResults
						WHERE   DatabaseName IN ( SELECT    DatabaseName
												  FROM      #SkipChecks
												  WHERE CheckID IS NULL
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName')));
						DELETE  FROM #BlitzResults
						WHERE   CheckID IN ( SELECT    CheckID
												  FROM      #SkipChecks
												  WHERE DatabaseName IS NULL
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName')));
						DELETE r FROM #BlitzResults r
							INNER JOIN #SkipChecks c ON r.DatabaseName = c.DatabaseName and r.CheckID = c.CheckID
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName'));
					END

				/* Add summary mode */
				IF @SummaryMode > 0
					BEGIN
					UPDATE #BlitzResults
					  SET Finding = br.Finding + ' (' + CAST(brTotals.recs AS NVARCHAR(20)) + ')'
					  FROM #BlitzResults br
						INNER JOIN (SELECT FindingsGroup, Finding, Priority, COUNT(*) AS recs FROM #BlitzResults 
							GROUP BY FindingsGroup, Finding, Priority) brTotals ON br.FindingsGroup = brTotals.FindingsGroup AND br.Finding = brTotals.Finding AND br.Priority = brTotals.Priority
						WHERE brTotals.recs > 1;

					DELETE br
					  FROM #BlitzResults br
					  WHERE EXISTS (SELECT * FROM #BlitzResults brLower 
					  WHERE br.FindingsGroup = brLower.FindingsGroup AND br.Finding = brLower.Finding AND br.Priority = brLower.Priority AND br.ID > brLower.ID);

					END

				/* Add credits for the nice folks who put so much time into building and maintaining this for free: */
				/*  -- choi bo ra  주석화
				INSERT  INTO #BlitzResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details
						)
				VALUES  ( -1 ,
						  255 ,
						  'Thanks!' ,
						  'From Brent Ozar Unlimited' ,
						  'http://www.BrentOzar.com/blitz/' ,
						  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
						);

				INSERT  INTO #BlitzResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details

						)
				VALUES  ( -1 ,
						  0 ,
						  'sp_Blitz (TM) v' + CAST(@Version AS VARCHAR(20)) + ' as of ' + CAST(CONVERT(DATETIME, @VersionDate, 102) AS VARCHAR(100)),
						  'From Brent Ozar Unlimited' ,
						  'http://www.BrentOzar.com/blitz/' ,
						  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'

						);
				*/
				
				
				IF @EmailRecipients IS NOT NULL
					BEGIN
					/* Database mail won't work off a local temp table. I'm not happy about this hacky workaround either. */
					IF (OBJECT_ID('tempdb..##BlitzResults', 'U') IS NOT NULL) DROP TABLE ##BlitzResults;
					SELECT * INTO ##BlitzResults FROM #BlitzResults;
					SET @query_result_separator = char(9);
					SET @StringToExecute = 'SET NOCOUNT ON;SELECT [Priority] , [FindingsGroup] , [Finding] , [DatabaseName] , [URL] ,  [Details] 
					, CheckID, [ObjectName] FROM ##BlitzResults ORDER BY Priority , FindingsGroup, Finding, Details; SET NOCOUNT OFF;';
					SET @EmailSubject = 'sp_Blitz (TM) Results for ' + @@SERVERNAME;
					SET @EmailBody = 'sp_Blitz (TM) v' + CAST(@Version AS VARCHAR(20)) + ' as of ' + CAST(CONVERT(DATETIME, @VersionDate, 102) AS VARCHAR(100)) + 
					'. From Brent Ozar Unlimited: http://www.BrentOzar.com/blitz/';
					IF @EmailProfile IS NULL
						EXEC msdb.dbo.sp_send_dbmail
							@recipients = @EmailRecipients,
							@subject = @EmailSubject,
							@body = @EmailBody,
							@query_attachment_filename = 'sp_Blitz-Results.csv',
							@attach_query_result_as_file = 1,
							@query_result_header = 1,
							@query_result_width = 32767,
							@append_query_error = 1,
							@query_result_no_padding = 1,
							@query_result_separator = @query_result_separator,
							@query = @StringToExecute;
					ELSE
						EXEC msdb.dbo.sp_send_dbmail
							@profile_name = @EmailProfile,
							@recipients = @EmailRecipients,
							@subject = @EmailSubject,
							@body = @EmailBody,
							@query_attachment_filename = 'sp_Blitz-Results.csv',
							@attach_query_result_as_file = 1,
							@query_result_header = 1,
							@query_result_width = 32767,
							@append_query_error = 1,
							@query_result_no_padding = 1,
							@query_result_separator = @query_result_separator,
							@query = @StringToExecute;
					IF (OBJECT_ID('tempdb..##BlitzResults', 'U') IS NOT NULL) DROP TABLE ##BlitzResults;
				END


				/* @OutputTableName lets us export the results to a permanent table */
				IF @OutputDatabaseName IS NOT NULL
					AND @OutputSchemaName IS NOT NULL
					AND @OutputTableName IS NOT NULL
					AND EXISTS ( SELECT *
								 FROM   sys.databases
								 WHERE  QUOTENAME([name]) = @OutputDatabaseName)
					BEGIN
					
						SET @StringToExecute = 'USE '
							+ @OutputDatabaseName
							+ '; IF EXISTS(SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
							+ @OutputSchemaName
							+ ''') AND NOT EXISTS (SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
							+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
							+ @OutputTableName + ''') CREATE TABLE '
							+ @OutputSchemaName + '.'
							+ @OutputTableName
							+ ' (ID INT IDENTITY(1,1) NOT NULL,
								ServerName NVARCHAR(128),
								CheckDate DATETIME,
							--	BlitzVersion INT,
								Priority TINYINT ,
								FindingsGroup VARCHAR(50) ,
								Finding VARCHAR(200) ,
								DatabaseName NVARCHAR(128),
								ObjectName	NVARCHAR(128),
								--URL VARCHAR(200) ,  by choi bo ra 반복 제거 
								Details NVARCHAR(4000) ,
								QueryPlan [XML] NULL ,
								QueryPlanFiltered [NVARCHAR](MAX) NULL,
								CheckID INT ,
								CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
						
						
						EXEC(@StringToExecute);

						
						SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
							+ @OutputSchemaName + ''') INSERT '
							+ @OutputDatabaseName + '.'
							+ @OutputSchemaName + '.'
							+ @OutputTableName
							+ ' (SERVER_ID, ServerName, CheckDate, ' --BlitzVersion,'
							+ ' CheckID, DatabaseName, ObjectName, Priority, FindingsGroup, Finding,' --URL
							+ '  Details, QueryPlan, QueryPlanFiltered) SELECT '+ CONVERT(NVARCHAR(10), @SERVER_ID) + ','''
							+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
							+ ''', GETDATE() '  --+ CAST(@Version AS NVARCHAR(128))
							+ ', CheckID, DatabaseName, ObjectName, Priority, FindingsGroup, Finding' --URL, ' 
							+ ' ,Details, QueryPlan, QueryPlanFiltered ' 
							+ ' FROM #BlitzResults ORDER BY Priority , FindingsGroup , Finding , Details';
						PRINT @StringToExecute
						EXEC(@StringToExecute);
				
					END
					
				ELSE IF (SUBSTRING(@OutputTableName, 2, 2) = '##')
					BEGIN
						SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
							+ @OutputTableName
							+ ''') IS NOT NULL) DROP TABLE ' + @OutputTableName + ';'
							+ 'CREATE TABLE '
							+ @OutputTableName
							+ ' (ID INT IDENTITY(1,1) NOT NULL,
								ServerName NVARCHAR(128),
								CheckDate DATETIME,
								BlitzVersion INT,
								Priority TINYINT ,
								FindingsGroup VARCHAR(50) ,
								Finding VARCHAR(200) ,
								DatabaseName NVARCHAR(128),
								--URL VARCHAR(200) ,  by choi bo ra 반복 제거 
								ObjectName		nvarchar(128),
								Details NVARCHAR(4000) ,
								QueryPlan [XML] NULL ,
								QueryPlanFiltered [NVARCHAR](MAX) NULL,
								CheckID INT ,
								CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
							+ ' INSERT '
							+ @OutputTableName
							+ ' (ServerName, CheckDate, BlitzVersion, CheckID, DatabaseName, ObjectName,  Priority, FindingsGroup, Finding,' -- URL, 
							+ ' Details, QueryPlan, QueryPlanFiltered) SELECT '''
							+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
							+ ''', GETDATE(), ' + CAST(@Version AS NVARCHAR(128))
							+ ', CheckID, DatabaseName, ObjectName, Priority, FindingsGroup, Finding,' --URL, 
							+ ' Details, QueryPlan, QueryPlanFiltered FROM #BlitzResults ORDER BY Priority , FindingsGroup , Finding , Details';
						EXEC(@StringToExecute);
					END
				ELSE IF (SUBSTRING(@OutputTableName, 2, 1) = '#')
					BEGIN
						RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
					END


				DECLARE @separator AS VARCHAR(1);
				IF @OutputType = 'RSV'
					SET @separator = CHAR(31);
				ELSE
					SET @separator = ',';

				IF @OutputType = 'COUNT'
					BEGIN
						SELECT  COUNT(*) AS Warnings
						FROM    #BlitzResults
					END
				ELSE
					IF @OutputType IN ( 'CSV', 'RSV' )
						BEGIN

							SELECT  Result = CAST([Priority] AS NVARCHAR(100))
									+ @separator + CAST(CheckID AS NVARCHAR(100))
									+ @separator + COALESCE([FindingsGroup],
															'(N/A)') + @separator
									+ COALESCE([Finding], '(N/A)') + @separator
									+ COALESCE(DatabaseName, '(N/A)') + @separator
									+ COALESCE(ObjectName, '(N/A)') + @separator
									+ COALESCE([URL], '(N/A)') + @separator
									+ COALESCE([Details], '(N/A)')
							FROM    #BlitzResults
							ORDER BY Priority ,
									FindingsGroup ,
									Finding ,
									Details;
						END
						ELSE IF @OutputXMLasNVARCHAR = 1
						BEGIN
							SELECT  [Priority] ,
									[FindingsGroup] ,
									[Finding] ,
									[DatabaseName] ,
									[ObjectName], 
									--[URL] ,
									[Details] ,
									CAST([QueryPlan] AS NVARCHAR(MAX)) AS QueryPlan,
									[QueryPlanFiltered] ,
									CheckID
							FROM    #BlitzResults
							ORDER BY Priority ,
									FindingsGroup ,
									Finding ,
									Details;
						END
					-- 주석 처리 choi bo ra, 테이블 저장 하기 때문
					--ELSE
					--	BEGIN
					--		SELECT  [Priority] ,
					--				[FindingsGroup] ,
					--				[Finding] ,
					--				[DatabaseName] ,
					--				[ObjectName], 
					--				--[URL] ,
					--				[Details] ,
					--				[QueryPlan] ,
					--				[QueryPlanFiltered] ,
					--				CheckID
					--		FROM    #BlitzResults
					--		ORDER BY Priority ,
					--				FindingsGroup ,
					--				Finding ,
					--				Details;
					--END

				DROP TABLE #BlitzResults;

				IF @OutputProcedureCache = 1
					AND @CheckProcedureCache = 1
					SELECT TOP 20
							total_worker_time / execution_count AS AvgCPU ,
							total_worker_time AS TotalCPU ,
							CAST(ROUND(100.00 * total_worker_time
									   / ( SELECT   SUM(total_worker_time)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentCPU ,
							total_elapsed_time / execution_count AS AvgDuration ,
							total_elapsed_time AS TotalDuration ,
							CAST(ROUND(100.00 * total_elapsed_time
									   / ( SELECT   SUM(total_elapsed_time)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentDuration ,
							total_logical_reads / execution_count AS AvgReads ,
							total_logical_reads AS TotalReads ,
							CAST(ROUND(100.00 * total_logical_reads
									   / ( SELECT   SUM(total_logical_reads)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentReads ,
							execution_count ,
							CAST(ROUND(100.00 * execution_count
									   / ( SELECT   SUM(execution_count)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentExecutions ,
							CASE WHEN DATEDIFF(mi, creation_time,
											   qs.last_execution_time) = 0 THEN 0
								 ELSE CAST(( 1.00 * execution_count / DATEDIFF(mi,
																  creation_time,
																  qs.last_execution_time) ) AS MONEY)
							END AS executions_per_minute ,
							qs.creation_time AS plan_creation_time ,
							qs.last_execution_time ,
							text ,
							text_filtered ,
							query_plan ,
							query_plan_filtered ,
							sql_handle ,
							query_hash ,
							plan_handle ,
							query_plan_hash
					FROM    #dm_exec_query_stats qs
					ORDER BY CASE UPPER(@CheckProcedureCacheFilter)
							   WHEN 'CPU' THEN total_worker_time
							   WHEN 'READS' THEN total_logical_reads
							   WHEN 'EXECCOUNT' THEN execution_count
							   WHEN 'DURATION' THEN total_elapsed_time
							   ELSE total_worker_time
							 END DESC

	END /* ELSE -- IF @OutputType = 'SCHEMA' */
    SET NOCOUNT OFF;


go

CREATE PROCEDURE dbo.sp_BlitzIndex_dba
	@SERVER_ID	INT,
	@DatabaseName NVARCHAR(128) = null, /*Defaults to current DB if not specified*/
	@Mode tinyint=0, /*0=diagnose, 1=Summarize, 2=Index Usage Detail, 3=Missing Index Detail*/
	@SchemaName NVARCHAR(128) = NULL, /*Requires table_name as well.*/
	@TableName NVARCHAR(128) = NULL,  /*Requires schema_name as well.*/
		/*Note:@Mode doesn't matter if you're specifying schema_name and @TableName.*/
	@Filter tinyint = 0 /* 0=no filter (default). 1=No low-usage warnings for objects with 0 reads. 2=Only warn for objects >= 500MB */
		/*Note:@Filter doesn't do anything unless @Mode=0*/
/*
sp_BlitzIndex(TM) v2.02 - Jan 30, 2014

(C) 2014, Brent Ozar Unlimited(TM). 
See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

For help and how-to info, visit http://www.BrentOzar.com/BlitzIndex

How to use:
--	Diagnose:
		EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks';
--	Return detail for a specific table:
		EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Person', @TableName='Person';

Known limitations of this version:
 - Does not include FULLTEXT indexes. (A possibility in the future, let us know if you're interested.)
 - Index create statements are just to give you a rough idea of the syntax. It includes filters and fillfactor.
 --		Example 1: index creates use ONLINE=? instead of ONLINE=ON / ONLINE=OFF. This is because it's important for the user to understand if it's going to be offline and not just run a script.
 --		Example 2: they do not include all the options the index may have been created with (padding, compression filegroup/partition scheme etc.)
 --		(The compression and filegroup index create syntax isn't trivial because it's set at the partition level and isn't trivial to code. Two people have voted for wanting it so far.)
 - Doesn't advise you about data modeling for clustered indexes and primary keys (primarily looks for signs of insanity.)
 - Found something? Let us know at help@brentozar.com.

 Thanks for using sp_BlitzIndex(TM)!
 Sincerely,
 The Humans of Brent Ozar Unlimited(TM)

CHANGE LOG (last five versions):
	Jan 30, 2014 (v2.02)
		Standardized calling parameters with sp_AskBrent(TM) and sp_BlitzIndex(TM). (@DatabaseName instead of @database_name, etc)
		Added check_id 80 and 81-- what appear to be the most frequently used indexes (workaholics)
		Added index_operational_stats info to table level output -- recent scans vs lookups
		Broke index_usage_stats output into two categories, scans and lookups (also in table level output)
		Changed db name, table name, index name to 128 length
		Fixed findings_group column length in #BlitzIndexResults (fixed issues for users w/ longer db names)
		Fixed issue where identities nearing end of range were only detected if the check was run with a specific db context
			Fixed extra tab in @SchemaName= that made pasting into Excel awkward/wrong
		Added abnormal psychology check for clustered columnstore indexes (and general support for detecting them)
		Standardized underscores in create TSQL for missing indexes
		Better error message when running in table mode and the table isn't found.
		Added current timestamp to the header based on user request. (Didn't add startup time-- sorry! Too many things reset usage info, don't want to mislead anyone.)
		Added fillfactor to index create statements.
		Changed all index create statements to ONLINE=?, SORT_IN_TEMPDB=?. The user should decide at index create time what's right for them.
	May 26, 2013 (v2.01)
		Added check_id 28: Non-unqiue clustered indexes. (This should have been checked in for an earlier version, it slipped by).
	May 14, 2013 (v2.0) - Added data types and max length to all columns (keys, includes, secret columns)
		Set sp_blitz to default to current DB if database_name is not specified when called
		Added @Filter:  
			0=no filter (default)
			1=Don't throw low-usage warnings for objects with 0 reads (helpful for dev/non-production environments)
			2=Only report on objects >= 250MB (helps focus on larger indexes). Still runs a few database-wide checks as well.
		Added list of all columns and types in table for runs using: @DatabaseName, @SchemaName, @TableName
		Added count of total number of indexes a column is part of.
		Added check_id 25: Addicted to nullable columns. (All or all but one column is nullable.)
		Added check_id 66 and 67 to flag tables/indexes created within 1 week or modified within 48 hours.
		Added check_id 26: Wide tables (35+ cols or > 2000 non-LOB bytes).
		Added check_id 27: Addicted to strings. Looks for tables with 4 or more columns, of which all or all but one are string or LOB types.
		Added check_id 68: Identity columns within 30% of the end of range (tinyint, smallint, int) AND
			Negative identity seeds or identity increments <> 1
		Added check_id 69: Column collation does not match database collation
		Added check_id 70: Replicated columns. This identifies which columns are in at least one replication publication.
		Added check_id 71: Cascading updates or cascading deletes.
		Split check_id 40 into two checks: fillfactor on nonclustered indexes < 80%, fillfactor on clustered indexes < 90%
		Added check_id 33: Potential filtered indexes based on column names.
		Fixed bug where you couldn't see detailed view for indexed views. 
			(Ex: EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Production', @TableName='vProductAndDescription';)
		Added four index usage columns to table detail output: last_user_seek, last_user_scan, last_user_lookup, last_user_update
		Modified check_id 24. This now looks for wide clustered indexes (> 3 columns OR > 16 bytes).
			Previously just simplistically looked for multiple column CX.
		Removed extra spacing (non-breaking) in more_info column.
		Fixed bug where create t-sql didn't include filter (for filtered indexes)
		Fixed formatting bug where "magic number" in table detail view didn't have commas
		Neatened up column names in result sets.
	April 8, 2013 (v1.5) - Fixed breaking bug for partitioned tables with > 10(ish) partitions
		Added schema_name to suggested create statement for PKs
		Handled "magic_benefit_number" values for missing indexes >= 922,337,203,685,477
		Added count of NC indexes to Index Hoarder: Multi-column clustered index finding
		Added link to EULA
		Simplified aggressive index checks (blocking). Multiple checks confused people more than it helped.
			Left only "Total lock wait time > 5 minutes (row + page)".
		Added CheckId 25 for non-unique clustered indexes. 
		The "Create TSQL" column now shows a commented out drop command for disabled non-clustered indexes
		Updated query which joins to sys.dm_operational_stats DMV when running against 2012 for performance reasons
	December 20, 2012 (v1.4) - Fixed bugs for instances using a case-sensitive collation
		Added support to identify compressed indexes
		Added basic support for columnstore, XML, and spatial indexes
		Added "Abnormal Psychology" diagnosis to alert you to special index types in a database
		Removed hypothetical indexes and disabled indexes from "multiple personality disorders"
		Fixed bug where hypothetical indexes weren't showing up in "self-loathing indexes"
		Fixed bug where the partitioning key column was displayed in the key of aligned nonclustered indexes on partitioned tables
		Added set options to the script so procedure is created with required settings for its use of computed columns

*/
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET QUERY_GOVERNOR_COST_LIMIT 0

DECLARE	@DatabaseID INT;
DECLARE @ObjectID INT;
DECLARE	@dsql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
DECLARE	@msg NVARCHAR(4000);
DECLARE	@ErrorSeverity INT;
DECLARE	@ErrorState INT;
DECLARE	@Rowcount BIGINT;
DECLARE @SQLServerProductVersion NVARCHAR(128);
DECLARE @SQLServerEdition INT;
DECLARE @FilterMB INT;
DECLARE @collation NVARCHAR(256);


SELECT @SQLServerProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
SELECT @SQLServerEdition =CAST(SERVERPROPERTY('EngineEdition') AS INT); /* We default to online index creates where EngineEdition=3*/
SET @FilterMB=250;

IF @DatabaseName is null 
	SET @DatabaseName=DB_NAME();

SELECT	@DatabaseID = database_id
FROM	sys.databases
WHERE	[name] = @DatabaseName
	AND user_access_desc='MULTI_USER'
	AND state_desc = 'ONLINE';

----------------------------------------
--STEP 1: OBSERVE THE PATIENT
--This step puts index information into temp tables.
----------------------------------------
BEGIN TRY
	BEGIN

		--Validate SQL Server Verson

		IF (SELECT LEFT(@SQLServerProductVersion,
			  CHARINDEX('.',@SQLServerProductVersion,0)-1
			  )) <= 8
		BEGIN
			SET @msg=N'sp_BlitzIndex is only supported on SQL Server 2005 and higher. The version of this instance is: ' + @SQLServerProductVersion;
			RAISERROR(@msg,16,1);
		END

		--Short circuit here if database name does not exist.
		IF @DatabaseName IS NULL OR @DatabaseID IS NULL
		BEGIN
			SET @msg='Database does not exist or is not online/multi-user: cannot proceed.'
			RAISERROR(@msg,16,1);
		END    

		--Validate parameters.
		IF (@Mode NOT IN (0,1,2,3))
		BEGIN
			SET @msg=N'Invalid @Mode parameter. 0=diagnose, 1=summarize, 2=index detail, 3=missing index detail';
			RAISERROR(@msg,16,1);
		END

		IF (@Mode <> 0 AND @TableName IS NOT NULL)
		BEGIN
			SET @msg=N'Setting the @Mode doesn''t change behavior if you supply @TableName. Use default @Mode=0 to see table detail.';
			RAISERROR(@msg,16,1);
		END

		IF ((@Mode <> 0 OR @TableName IS NOT NULL) and @Filter <> 0)
		BEGIN
			SET @msg=N'@Filter only appies when @Mode=0 and @TableName is not specified. Please try again.';
			RAISERROR(@msg,16,1);
		END

		IF (@SchemaName IS NOT NULL AND @TableName IS NULL) 
		BEGIN
			SET @msg='We can''t run against a whole schema! Specify a @TableName, or leave both NULL for diagnosis.'
			RAISERROR(@msg,16,1);
		END


		IF  (@TableName IS NOT NULL AND @SchemaName IS NULL)
		BEGIN
			SET @SchemaName=N'dbo'
			SET @msg='@SchemaName wasn''t specified-- assuming schema=dbo.'
			RAISERROR(@msg,1,1) WITH NOWAIT;
		END

		--If a table is specified, grab the object id.
		--Short circuit if it doesn't exist.
		IF @TableName IS NOT NULL
		BEGIN
			SET @dsql = N'
					SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
					SELECT	@ObjectID= OBJECT_ID
					FROM	' + QUOTENAME(@DatabaseName) + N'.sys.objects AS so
					JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.schemas AS sc on 
						so.schema_id=sc.schema_id
					where so.type in (''U'', ''V'')
					and so.name=' + QUOTENAME(@TableName,'''')+ N'
					and sc.name=' + QUOTENAME(@SchemaName,'''')+ N'
					/*Has a row in sys.indexes. This lets us get indexed views.*/
					and exists (
						SELECT si.name
						FROM ' + QUOTENAME(@DatabaseName) + '.sys.indexes AS si 
						WHERE so.object_id=si.object_id)
					OPTION (RECOMPILE);';

			SET @params='@ObjectID INT OUTPUT'				

			IF @dsql IS NULL 
				RAISERROR('@dsql is null',16,1);

			EXEC sp_executesql @dsql, @params, @ObjectID=@ObjectID OUTPUT;
			
			IF @ObjectID IS NULL
					BEGIN
						SET @msg=N'Oh, this is awkward. I can''t find the table or indexed view you''re looking for in that database.' + CHAR(10) +
							N'Please check your parameters.'
						RAISERROR(@msg,1,1);
						RETURN;
					END
		END

		RAISERROR(N'Starting run. sp_BlitzIndex(TM) v2.02 - Jan 30, 2014', 0,1) WITH NOWAIT;

		IF OBJECT_ID('tempdb..#IndexSanity') IS NOT NULL 
			DROP TABLE #IndexSanity;

		IF OBJECT_ID('tempdb..#IndexPartitionSanity') IS NOT NULL 
			DROP TABLE #IndexPartitionSanity;

		IF OBJECT_ID('tempdb..#IndexSanitySize') IS NOT NULL 
			DROP TABLE #IndexSanitySize;

		IF OBJECT_ID('tempdb..#IndexColumns') IS NOT NULL 
			DROP TABLE #IndexColumns;

		IF OBJECT_ID('tempdb..#MissingIndexes') IS NOT NULL 
			DROP TABLE #MissingIndexes;

		IF OBJECT_ID('tempdb..#ForeignKeys') IS NOT NULL 
			DROP TABLE #ForeignKeys;

		IF OBJECT_ID('tempdb..#BlitzIndexResults') IS NOT NULL 
			DROP TABLE #BlitzIndexResults;
		
		IF OBJECT_ID('tempdb..#IndexCreateTsql') IS NOT NULL	
			DROP TABLE #IndexCreateTsql;

		RAISERROR (N'Create temp tables.',0,1) WITH NOWAIT;
		
		CREATE TABLE #BlitzIndexResults
			(
			  blitz_result_id INT IDENTITY PRIMARY KEY,
			  check_id INT NOT NULL,
			  index_sanity_id INT NULL,
			  findings_group VARCHAR(4000) NOT NULL,
			  finding VARCHAR(200) NOT NULL,
			  URL VARCHAR(200) NOT NULL,
			  details NVARCHAR(4000) NOT NULL,
			  index_definition NVARCHAR(MAX) NOT NULL,
			  secret_columns NVARCHAR(MAX) NULL,
			  index_usage_summary NVARCHAR(MAX) NULL,
			  index_size_summary NVARCHAR(MAX) NULL,
			  create_tsql NVARCHAR(MAX) NULL,
			  more_info NVARCHAR(MAX)NULL
			);
			
		/*	
		CREATE TABLE #BlitzIndexResults
			(
			  blitz_result_id INT IDENTITY PRIMARY KEY,
			  check_id INT NOT NULL,
			  index_sanity_id INT NULL,
			  database_name	sysname not null,
			  table_name		sysname not null, 
			  findings_group VARCHAR(4000) NOT NULL,
			  finding VARCHAR(200) NOT NULL,
			  URL VARCHAR(200) NOT NULL,
			  details NVARCHAR(4000) NOT NULL,
			  index_definition NVARCHAR(MAX) NOT NULL,
			  secret_columns NVARCHAR(MAX) NULL,
			  reades			int not null, 
			  writes			int not null, 
			  index_usage_summary NVARCHAR(MAX) NULL,
			  rows			int null, 
			  reserved	int null, 
			  reserved_lob	int null, 
			  reserved_overflow int null,
			  index_size_summary NVARCHAR(MAX) NULL,
			  create_tsql NVARCHAR(MAX) NULL,
			  more_info NVARCHAR(MAX)NULL
			);
		*/
		CREATE TABLE #IndexSanity
			(
			  [index_sanity_id] INT IDENTITY PRIMARY KEY,
			  [database_id] SMALLINT NOT NULL ,
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [index_type] TINYINT NOT NULL,
			  [database_name] NVARCHAR(128) NOT NULL ,
			  [schema_name] NVARCHAR(128) NOT NULL ,
			  [object_name] NVARCHAR(128) NOT NULL ,
			  index_name NVARCHAR(128) NULL ,
			  key_column_names NVARCHAR(MAX) NULL ,
			  key_column_names_with_sort_order NVARCHAR(MAX) NULL ,
			  key_column_names_with_sort_order_no_types NVARCHAR(MAX) NULL ,
			  count_key_columns INT NULL ,
			  include_column_names NVARCHAR(MAX) NULL ,
			  include_column_names_no_types NVARCHAR(MAX) NULL ,
			  count_included_columns INT NULL ,
			  partition_key_column_name NVARCHAR(MAX) NULL,
			  filter_definition NVARCHAR(MAX) NOT NULL ,
			  is_indexed_view BIT NOT NULL ,
			  is_unique BIT NOT NULL ,
			  is_primary_key BIT NOT NULL ,
			  is_XML BIT NOT NULL,
			  is_spatial BIT NOT NULL,
			  is_NC_columnstore BIT NOT NULL,
			  is_CX_columnstore BIT NOT NULL,
			  is_disabled BIT NOT NULL ,
			  is_hypothetical BIT NOT NULL ,
			  is_padded BIT NOT NULL ,
			  fill_factor SMALLINT NOT NULL ,
			  user_seeks BIGINT NOT NULL ,
			  user_scans BIGINT NOT NULL ,
			  user_lookups BIGINT NOT  NULL ,
			  user_updates BIGINT NULL ,
			  last_user_seek DATETIME NULL ,
			  last_user_scan DATETIME NULL ,
			  last_user_lookup DATETIME NULL ,
			  last_user_update DATETIME NULL ,
			  is_referenced_by_foreign_key BIT DEFAULT(0),
			  secret_columns NVARCHAR(MAX) NULL,
			  count_secret_columns INT NULL,
			  create_date DATETIME NOT NULL,
			  modify_date DATETIME NOT NULL
			);	

		CREATE TABLE #IndexPartitionSanity
			(
			  [index_partition_sanity_id] INT IDENTITY PRIMARY KEY ,
			  [index_sanity_id] INT NULL ,
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [partition_number] INT NOT NULL ,
			  row_count BIGINT NOT NULL ,
			  reserved_MB NUMERIC(29,2) NOT NULL ,
			  reserved_LOB_MB NUMERIC(29,2) NOT NULL ,
			  reserved_row_overflow_MB NUMERIC(29,2) NOT NULL ,
			  leaf_insert_count BIGINT NULL ,
			  leaf_delete_count BIGINT NULL ,
			  leaf_update_count BIGINT NULL ,
			  range_scan_count BIGINT NULL ,
			  singleton_lookup_count BIGINT NULL , 
			  forwarded_fetch_count BIGINT NULL ,
			  lob_fetch_in_pages BIGINT NULL ,
			  lob_fetch_in_bytes BIGINT NULL ,
			  row_overflow_fetch_in_pages BIGINT NULL ,
			  row_overflow_fetch_in_bytes BIGINT NULL ,
			  row_lock_count BIGINT NULL ,
			  row_lock_wait_count BIGINT NULL ,
			  row_lock_wait_in_ms BIGINT NULL ,
			  page_lock_count BIGINT NULL ,
			  page_lock_wait_count BIGINT NULL ,
			  page_lock_wait_in_ms BIGINT NULL ,
			  index_lock_promotion_attempt_count BIGINT NULL ,
			  index_lock_promotion_count BIGINT NULL,
  			  data_compression_desc VARCHAR(60) NULL
			);

		CREATE TABLE #IndexSanitySize
			(
			  [index_sanity_size_id] INT IDENTITY NOT NULL ,
			  [index_sanity_id] INT NOT NULL ,
			  partition_count INT NOT NULL ,
			  total_rows BIGINT NOT NULL ,
			  total_reserved_MB NUMERIC(29,2) NOT NULL ,
			  total_reserved_LOB_MB NUMERIC(29,2) NOT NULL ,
			  total_reserved_row_overflow_MB NUMERIC(29,2) NOT NULL ,
			  total_leaf_delete_count BIGINT NULL,
			  total_leaf_update_count BIGINT NULL,
			  total_range_scan_count BIGINT NULL,
			  total_singleton_lookup_count BIGINT NULL,
			  total_forwarded_fetch_count BIGINT NULL,
			  total_row_lock_count BIGINT NULL ,
			  total_row_lock_wait_count BIGINT NULL ,
			  total_row_lock_wait_in_ms BIGINT NULL ,
			  avg_row_lock_wait_in_ms BIGINT NULL ,
			  total_page_lock_count BIGINT NULL ,
			  total_page_lock_wait_count BIGINT NULL ,
			  total_page_lock_wait_in_ms BIGINT NULL ,
			  avg_page_lock_wait_in_ms BIGINT NULL ,
 			  total_index_lock_promotion_attempt_count BIGINT NULL ,
			  total_index_lock_promotion_count BIGINT NULL ,
			  data_compression_desc VARCHAR(8000) NULL
			);

		CREATE TABLE #IndexColumns
			(
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [key_ordinal] INT NULL ,
			  is_included_column BIT NULL ,
			  is_descending_key BIT NULL ,
			  [partition_ordinal] INT NULL ,
			  column_name NVARCHAR(256) NOT NULL ,
			  system_type_name NVARCHAR(256) NOT NULL,
			  max_length SMALLINT NOT NULL,
			  [precision] TINYINT NOT NULL,
			  [scale] TINYINT NOT NULL,
			  collation_name NVARCHAR(256) NULL,
			  is_nullable bit NULL,
			  is_identity bit NULL,
			  is_computed bit NULL,
			  is_replicated bit NULL,
			  is_sparse bit NULL,
			  is_filestream bit NULL,
			  seed_value BIGINT NULL,
			  increment_value INT NULL ,
			  last_value BIGINT NULL,
			  is_not_for_replication BIT NULL
			);

		CREATE TABLE #MissingIndexes
			([object_id] INT NOT NULL,
			[database_name] NVARCHAR(128) NOT NULL ,
			[schema_name] NVARCHAR(128) NOT NULL ,
			[table_name] NVARCHAR(128),
			[statement] NVARCHAR(512) NOT NULL,
			magic_benefit_number AS (( user_seeks + user_scans ) * avg_total_user_cost * avg_user_impact),
			avg_total_user_cost NUMERIC(29,1) NOT NULL,
			avg_user_impact NUMERIC(29,1) NOT NULL,
			user_seeks BIGINT NOT NULL,
			user_scans BIGINT NOT NULL,
			unique_compiles BIGINT NULL,
			equality_columns NVARCHAR(4000), 
			inequality_columns NVARCHAR(4000),
			included_columns NVARCHAR(4000)
			);

		CREATE TABLE #ForeignKeys (
			foreign_key_name NVARCHAR(256),
			parent_object_id INT,
			parent_object_name NVARCHAR(256),
			referenced_object_id INT,
			referenced_object_name NVARCHAR(256),
			is_disabled BIT,
			is_not_trusted BIT,
			is_not_for_replication BIT,
			parent_fk_columns NVARCHAR(MAX),
			referenced_fk_columns NVARCHAR(MAX),
			update_referential_action_desc NVARCHAR(16),
			delete_referential_action_desc NVARCHAR(60)
		)
		
		CREATE TABLE #IndexCreateTsql (
			index_sanity_id INT NOT NULL,
			create_tsql NVARCHAR(MAX) NOT NULL
		)

		--set @collation
		SELECT @collation=collation_name
		FROM sys.databases
		where database_id=@DatabaseID;

		--insert columns for clustered indexes and heaps
		--collect info on identity columns for this one
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	
					si.object_id, 
					si.index_id, 
					sc.key_ordinal, 
					sc.is_included_column, 
					sc.is_descending_key,
					sc.partition_ordinal,
					c.name as column_name, 
					st.name as system_type_name,
					c.max_length,
					c.[precision],
					c.[scale],
					c.collation_name,
					c.is_nullable,
					c.is_identity,
					c.is_computed,
					c.is_replicated,
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_sparse' else N'NULL as is_sparse' END + N',
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_filestream' else N'NULL as is_filestream' END + N',
					CAST(ic.seed_value AS BIGINT),
					CAST(ic.increment_value AS INT),
					CAST(ic.last_value AS BIGINT),
					ic.is_not_for_replication
				FROM	' + QUOTENAME(@DatabaseName) + N'.sys.indexes si
				JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.columns c ON
					si.object_id=c.object_id
				LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.index_columns sc ON 
					sc.object_id = si.object_id
					and sc.index_id=si.index_id
					AND sc.column_id=c.column_id
				LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.identity_columns ic ON
					c.object_id=ic.object_id and
					c.column_id=ic.column_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types st ON 
					c.system_type_id=st.system_type_id
					AND c.user_type_id=st.user_type_id
				WHERE si.index_id in (0,1) ' 
					+ CASE WHEN @ObjectID IS NOT NULL 
						THEN N' AND si.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
					ELSE N'' END 
				+ N';';

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexColumns for clustered indexes and heaps',0,1) WITH NOWAIT;
		INSERT	#IndexColumns ( object_id, index_id, key_ordinal, is_included_column, is_descending_key, partition_ordinal,
			column_name, system_type_name, max_length, precision, scale, collation_name, is_nullable, is_identity, is_computed,
			is_replicated, is_sparse, is_filestream, seed_value, increment_value, last_value, is_not_for_replication )
				EXEC sp_executesql @dsql;

		--insert columns for nonclustered indexes
		--this uses a full join to sys.index_columns
		--We don't collect info on identity columns here. They may be in NC indexes, but we just analyze identities in the base table.
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	
					si.object_id, 
					si.index_id, 
					sc.key_ordinal, 
					sc.is_included_column, 
					sc.is_descending_key,
					sc.partition_ordinal,
					c.name as column_name, 
					st.name as system_type_name,
					c.max_length,
					c.[precision],
					c.[scale],
					c.collation_name,
					c.is_nullable,
					c.is_identity,
					c.is_computed,
					c.is_replicated,
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_sparse' else N'NULL AS is_sparse' END + N',
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_filestream' else N'NULL AS is_filestream' END + N'				
				FROM	' + QUOTENAME(@DatabaseName) + N'.sys.indexes AS si
				JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.columns AS c ON
					si.object_id=c.object_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.index_columns AS sc ON 
					sc.object_id = si.object_id
					and sc.index_id=si.index_id
					AND sc.column_id=c.column_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types AS st ON 
					c.system_type_id=st.system_type_id
					AND c.user_type_id=st.user_type_id
				WHERE si.index_id not in (0,1) ' 
					+ CASE WHEN @ObjectID IS NOT NULL 
						THEN N' AND si.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
					ELSE N'' END 
				+ N';';

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexColumns for nonclustered indexes',0,1) WITH NOWAIT;
		INSERT	#IndexColumns ( object_id, index_id, key_ordinal, is_included_column, is_descending_key, partition_ordinal,
			column_name, system_type_name, max_length, precision, scale, collation_name, is_nullable, is_identity, is_computed,
			is_replicated, is_sparse, is_filestream )
				EXEC sp_executesql @dsql;
					
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	' + CAST(@DatabaseID AS NVARCHAR(10)) + ' AS database_id, 
						so.object_id, 
						si.index_id, 
						si.type,
						' + QUOTENAME(@DatabaseName, '''') + ' AS database_name, 
						sc.NAME AS [schema_name],
						so.name AS [object_name], 
						si.name AS [index_name],
						CASE	WHEN so.[type] = CAST(''V'' AS CHAR(2)) THEN 1 ELSE 0 END, 
						si.is_unique, 
						si.is_primary_key, 
						CASE when si.type = 3 THEN 1 ELSE 0 END AS is_XML,
						CASE when si.type = 4 THEN 1 ELSE 0 END AS is_spatial,
						CASE when si.type = 6 THEN 1 ELSE 0 END AS is_NC_columnstore,
						CASE when si.type = 5 then 1 else 0 end as is_CX_columnstore,
						si.is_disabled,
						si.is_hypothetical, 
						si.is_padded, 
						si.fill_factor,'
						+ case when @SQLServerProductVersion not like '9%' THEN '
						CASE WHEN si.filter_definition IS NOT NULL THEN si.filter_definition
							 ELSE ''''
						END AS filter_definition' ELSE ''''' AS filter_definition' END + '
						, ISNULL(us.user_seeks, 0), ISNULL(us.user_scans, 0),
						ISNULL(us.user_lookups, 0), ISNULL(us.user_updates, 0), us.last_user_seek, us.last_user_scan,
						us.last_user_lookup, us.last_user_update,
						so.create_date, so.modify_date
				FROM	' + QUOTENAME(@DatabaseName) + '.sys.indexes AS si WITH (NOLOCK)
						JOIN ' + QUOTENAME(@DatabaseName) + '.sys.objects AS so WITH (NOLOCK) ON si.object_id = so.object_id
											   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
											   AND so.type <> ''TF'' /*Exclude table valued functions*/
						JOIN ' + QUOTENAME(@DatabaseName) + '.sys.schemas sc ON so.schema_id = sc.schema_id
						LEFT JOIN sys.dm_db_index_usage_stats AS us WITH (NOLOCK) ON si.[object_id] = us.[object_id]
																	   AND si.index_id = us.index_id
																	   AND us.database_id = '+ CAST(@DatabaseID AS NVARCHAR(10)) + '
				WHERE	si.[type] IN ( 0, 1, 2, 3, 4, 5, 6 ) 
				/* Heaps, clustered, nonclustered, XML, spatial, Cluster Columnstore, NC Columnstore */ ' +
				CASE WHEN @TableName IS NOT NULL THEN ' and so.name=' + QUOTENAME(@TableName,'''') + ' ' ELSE '' END + 
		'OPTION	( RECOMPILE );
		';
		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexSanity',0,1) WITH NOWAIT;
		-- Insert #IndexSanity
		INSERT	#IndexSanity ( [database_id], [object_id], [index_id], [index_type], [database_name], [schema_name], [object_name],
								index_name, is_indexed_view, is_unique, is_primary_key, is_XML, is_spatial, is_NC_columnstore, is_CX_columnstore,
								is_disabled, is_hypothetical, is_padded, fill_factor, filter_definition, user_seeks, user_scans, 
								user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update,
								create_date, modify_date )
				EXEC sp_executesql @dsql;

		RAISERROR (N'Updating #IndexSanity.key_column_names',0,1) WITH NOWAIT;
		
		UPDATE	#IndexSanity
		SET		key_column_names = D1.key_column_names
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name 
									+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
										AS col_definition
									FROM	#IndexColumns c
									WHERE	c.object_id = si.object_id
											AND c.index_id = si.index_id
											AND c.is_included_column = 0 /*Just Keys*/
											AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
									ORDER BY c.object_id, c.index_id, c.key_ordinal	
							FOR	  XML PATH('') ,TYPE).value('.', 'varchar(max)'), 1, 1, ''))
										) D1 ( key_column_names )

		RAISERROR (N'Updating #IndexSanity.partition_key_column_name',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		partition_key_column_name = D1.partition_key_column_name
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name AS col_definition
									FROM	#IndexColumns c
									WHERE	c.object_id = si.object_id
											AND c.index_id = si.index_id
											AND c.partition_ordinal <> 0 /*Just Partitioned Keys*/
									ORDER BY c.object_id, c.index_id, c.key_ordinal	
							FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1,''))) D1 
										( partition_key_column_name )

		RAISERROR (N'Updating #IndexSanity.key_column_names_with_sort_order',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		key_column_names_with_sort_order = D2.key_column_names_with_sort_order
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name + CASE c.is_descending_key
									WHEN 1 THEN N' DESC'
									ELSE N''
								+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
								END AS col_definition
							FROM	#IndexColumns c
							WHERE	c.object_id = si.object_id
									AND c.index_id = si.index_id
									AND c.is_included_column = 0 /*Just Keys*/
									AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
							ORDER BY c.object_id, c.index_id, c.key_ordinal	
					FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1, ''))
					) D2 ( key_column_names_with_sort_order )

		RAISERROR (N'Updating #IndexSanity.key_column_names_with_sort_order_no_types (for create tsql)',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		key_column_names_with_sort_order_no_types = D2.key_column_names_with_sort_order_no_types
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + QUOTENAME(c.column_name) + CASE c.is_descending_key
									WHEN 1 THEN N' [DESC]'
									ELSE N''
								END AS col_definition
							FROM	#IndexColumns c
							WHERE	c.object_id = si.object_id
									AND c.index_id = si.index_id
									AND c.is_included_column = 0 /*Just Keys*/
									AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
							ORDER BY c.object_id, c.index_id, c.key_ordinal	
					FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1, ''))
					) D2 ( key_column_names_with_sort_order_no_types )

		RAISERROR (N'Updating #IndexSanity.include_column_names',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		include_column_names = D3.include_column_names
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name
								+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
								FROM	#IndexColumns c
								WHERE	c.object_id = si.object_id
										AND c.index_id = si.index_id
										AND c.is_included_column = 1 /*Just includes*/
								ORDER BY c.column_name /*Order doesn't matter in includes, 
										this is here to make rows easy to compare.*/ 
						FOR	  XML PATH('') ,  TYPE).value('.', 'varchar(max)'), 1, 1, ''))
						) D3 ( include_column_names );

		RAISERROR (N'Updating #IndexSanity.include_column_names_no_types (for create tsql)',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		include_column_names_no_types = D3.include_column_names_no_types
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + QUOTENAME(c.column_name)
								FROM	#IndexColumns c
								WHERE	c.object_id = si.object_id
										AND c.index_id = si.index_id
										AND c.is_included_column = 1 /*Just includes*/
								ORDER BY c.column_name /*Order doesn't matter in includes, 
										this is here to make rows easy to compare.*/ 
						FOR	  XML PATH('') ,  TYPE).value('.', 'varchar(max)'), 1, 1, ''))
						) D3 ( include_column_names_no_types );

		RAISERROR (N'Updating #IndexSanity.count_key_columns and count_include_columns',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		count_included_columns = D4.count_included_columns,
				count_key_columns = D4.count_key_columns
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	SUM(CASE WHEN is_included_column = 'true' THEN 1
												 ELSE 0
											END) AS count_included_columns,
										SUM(CASE WHEN is_included_column = 'false' AND c.key_ordinal > 0 THEN 1
												 ELSE 0
											END) AS count_key_columns
							  FROM		#IndexColumns c
							  WHERE		c.object_id = si.object_id
										AND c.index_id = si.index_id 
										) AS D4 ( count_included_columns, count_key_columns );

		IF (SELECT LEFT(@SQLServerProductVersion,
			  CHARINDEX('.',@SQLServerProductVersion,0)-1
			  )) <> 11 --Anything other than 2012
		BEGIN

			RAISERROR (N'Using non-2012 syntax to query sys.dm_db_index_operational_stats',0,1) WITH NOWAIT;

			--NOTE: we're joining to sys.dm_db_index_operational_stats differently than you might think (not using a cross apply)
			--This is because of quirks prior to SQL Server 2012 and in 2014 with this DMV.
			SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
						SELECT	ps.object_id, 
								ps.index_id, 
								ps.partition_number, 
								ps.row_count,
								ps.reserved_page_count * 8. / 1024. AS reserved_MB,
								ps.lob_reserved_page_count * 8. / 1024. AS reserved_LOB_MB,
								ps.row_overflow_reserved_page_count * 8. / 1024. AS reserved_row_overflow_MB,
								os.leaf_insert_count, 
								os.leaf_delete_count, 
								os.leaf_update_count, 
								os.range_scan_count, 
								os.singleton_lookup_count,  
								os.forwarded_fetch_count,
								os.lob_fetch_in_pages, 
								os.lob_fetch_in_bytes, 
								os.row_overflow_fetch_in_pages,
								os.row_overflow_fetch_in_bytes, 
								os.row_lock_count, 
								os.row_lock_wait_count,
								os.row_lock_wait_in_ms, 
								os.page_lock_count, 
								os.page_lock_wait_count, 
								os.page_lock_wait_in_ms,
								os.index_lock_promotion_attempt_count, 
								os.index_lock_promotion_count, 
							' + case when @SQLServerProductVersion not like '9%' THEN 'par.data_compression_desc ' ELSE 'null as data_compression_desc' END + '
					FROM	' + QUOTENAME(@DatabaseName) + '.sys.dm_db_partition_stats AS ps  
					JOIN ' + QUOTENAME(@DatabaseName) + '.sys.partitions AS par on ps.partition_id=par.partition_id
					JOIN ' + QUOTENAME(@DatabaseName) + '.sys.objects AS so ON ps.object_id = so.object_id
							   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
							   AND so.type <> ''TF'' /*Exclude table valued functions*/
					LEFT JOIN ' + QUOTENAME(@DatabaseName) + '.sys.dm_db_index_operational_stats('
				+ CAST(@DatabaseID AS NVARCHAR(10)) + ', NULL, NULL,NULL) AS os ON
					ps.object_id=os.object_id and ps.index_id=os.index_id and ps.partition_number=os.partition_number 
					WHERE 1=1 
					' + CASE WHEN @ObjectID IS NOT NULL THEN N'AND so.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' ELSE N' ' END + '
					' + CASE WHEN @Filter = 2 THEN N'AND ps.reserved_page_count * 8./1024. > ' + CAST(@FilterMB AS NVARCHAR(5)) + N' ' ELSE N' ' END + '
			ORDER BY ps.object_id,  ps.index_id, ps.partition_number
			OPTION	( RECOMPILE );
			';
		END
		ELSE /* Otherwise use this syntax which takes advantage of OUTER APPLY on the os_partitions DMV. 
		This performs better on 2012 tables using 1000+ partitions. */
		BEGIN
		RAISERROR (N'Using 2012 syntax to query sys.dm_db_index_operational_stats',0,1) WITH NOWAIT;

 		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
						SELECT	ps.object_id, 
								ps.index_id, 
								ps.partition_number, 
								ps.row_count,
								ps.reserved_page_count * 8. / 1024. AS reserved_MB,
								ps.lob_reserved_page_count * 8. / 1024. AS reserved_LOB_MB,
								ps.row_overflow_reserved_page_count * 8. / 1024. AS reserved_row_overflow_MB,
								os.leaf_insert_count, 
								os.leaf_delete_count, 
								os.leaf_update_count, 
								os.range_scan_count, 
								os.singleton_lookup_count,  
								os.forwarded_fetch_count,
								os.lob_fetch_in_pages, 
								os.lob_fetch_in_bytes, 
								os.row_overflow_fetch_in_pages,
								os.row_overflow_fetch_in_bytes, 
								os.row_lock_count, 
								os.row_lock_wait_count,
								os.row_lock_wait_in_ms, 
								os.page_lock_count, 
								os.page_lock_wait_count, 
								os.page_lock_wait_in_ms,
								os.index_lock_promotion_attempt_count, 
								os.index_lock_promotion_count, 
								' + case when @SQLServerProductVersion not like '9%' THEN N'par.data_compression_desc ' ELSE N'null as data_compression_desc' END + N'
						FROM	' + QUOTENAME(@DatabaseName) + N'.sys.dm_db_partition_stats AS ps  
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.partitions AS par on ps.partition_id=par.partition_id
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects AS so ON ps.object_id = so.object_id
								   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
								   AND so.type <> ''TF'' /*Exclude table valued functions*/
						OUTER APPLY ' + QUOTENAME(@DatabaseName) + N'.sys.dm_db_index_operational_stats('
					+ CAST(@DatabaseID AS NVARCHAR(10)) + N', ps.object_id, ps.index_id,ps.partition_number) AS os
						WHERE 1=1 
						' + CASE WHEN @ObjectID IS NOT NULL THEN N'AND so.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' ELSE N' ' END + N'
						' + CASE WHEN @Filter = 2 THEN N'AND ps.reserved_page_count * 8./1024. > ' + CAST(@FilterMB AS NVARCHAR(5)) + N' ' ELSE N' ' END + '
				ORDER BY ps.object_id,  ps.index_id, ps.partition_number
				OPTION	( RECOMPILE );
				';
 
		END       

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

	 -- Insert  IndexPartitionSanity
		RAISERROR (N'Inserting data into #IndexPartitionSanity',0,1) WITH NOWAIT;
		insert	#IndexPartitionSanity ( 
											[object_id], 
											index_id, 
											partition_number, 
											row_count, 
											reserved_MB,
										  reserved_LOB_MB, 
										  reserved_row_overflow_MB, 
										  leaf_insert_count,
										  leaf_delete_count, 
										  leaf_update_count, 
										  range_scan_count,
										  singleton_lookup_count,
										  forwarded_fetch_count, 
										  lob_fetch_in_pages, 
										  lob_fetch_in_bytes, 
										  row_overflow_fetch_in_pages,
										  row_overflow_fetch_in_bytes, 
										  row_lock_count, 
										  row_lock_wait_count,
										  row_lock_wait_in_ms, 
										  page_lock_count, 
										  page_lock_wait_count,
										  page_lock_wait_in_ms, 
										  index_lock_promotion_attempt_count,
										  index_lock_promotion_count, 
										  data_compression_desc )
				EXEC sp_executesql @dsql;


		RAISERROR (N'Updating index_sanity_id on #IndexPartitionSanity',0,1) WITH NOWAIT;
		UPDATE	#IndexPartitionSanity
		SET		index_sanity_id = i.index_sanity_id
		FROM #IndexPartitionSanity ps
				JOIN #IndexSanity i ON ps.[object_id] = i.[object_id]
										AND ps.index_id = i.index_id


	 -- Index #IndexSanitySize
		RAISERROR (N'Inserting data into #IndexSanitySize',0,1) WITH NOWAIT;
		INSERT	#IndexSanitySize ( [index_sanity_id], partition_count, total_rows, total_reserved_MB,
									 total_reserved_LOB_MB, total_reserved_row_overflow_MB, total_range_scan_count,
									 total_singleton_lookup_count, total_leaf_delete_count, total_leaf_update_count, 
									 total_forwarded_fetch_count,total_row_lock_count,
									 total_row_lock_wait_count, total_row_lock_wait_in_ms, avg_row_lock_wait_in_ms,
									 total_page_lock_count, total_page_lock_wait_count, total_page_lock_wait_in_ms,
									 avg_page_lock_wait_in_ms, total_index_lock_promotion_attempt_count, 
									 total_index_lock_promotion_count, data_compression_desc )
				SELECT	index_sanity_id, COUNT(*), SUM(row_count), SUM(reserved_MB), SUM(reserved_LOB_MB),
						SUM(reserved_row_overflow_MB), 
						SUM(range_scan_count),
						SUM(singleton_lookup_count),
						SUM(leaf_delete_count), 
						SUM(leaf_update_count),
						SUM(forwarded_fetch_count),
						SUM(row_lock_count), 
						SUM(row_lock_wait_count),
						SUM(row_lock_wait_in_ms), 
						CASE WHEN SUM(row_lock_wait_in_ms) > 0 THEN
							SUM(row_lock_wait_in_ms)/(1.*SUM(row_lock_wait_count))
						ELSE 0 END AS avg_row_lock_wait_in_ms,           
						SUM(page_lock_count), 
						SUM(page_lock_wait_count),
						SUM(page_lock_wait_in_ms), 
						CASE WHEN SUM(page_lock_wait_in_ms) > 0 THEN
							SUM(page_lock_wait_in_ms)/(1.*SUM(page_lock_wait_count))
						ELSE 0 END AS avg_page_lock_wait_in_ms,           
						SUM(index_lock_promotion_attempt_count),
						SUM(index_lock_promotion_count),
						LEFT(MAX(data_compression_info.data_compression_rollup),8000)
				FROM #IndexPartitionSanity ipp
				/* individual partitions can have distinct compression settings, just roll them into a list here*/
				OUTER APPLY (SELECT STUFF((
					SELECT	N', ' + data_compression_desc
					FROM #IndexPartitionSanity ipp2
					WHERE ipp.[object_id]=ipp2.[object_id]
						AND ipp.[index_id]=ipp2.[index_id]
					ORDER BY ipp2.partition_number
					FOR	  XML PATH(''),TYPE).value('.', 'varchar(max)'), 1, 1, '')) 
						data_compression_info(data_compression_rollup)
				GROUP BY index_sanity_id
				ORDER BY index_sanity_id 
		OPTION	( RECOMPILE );

		RAISERROR (N'Adding UQ index on #IndexSanity (object_id,index_id)',0,1) WITH NOWAIT;
		CREATE UNIQUE INDEX uq_object_id_index_id ON #IndexSanity (object_id,index_id);

		RAISERROR (N'Inserting data into #MissingIndexes',0,1) WITH NOWAIT;
		SET @dsql=N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	id.object_id, ' + QUOTENAME(@DatabaseName,'''') + N', sc.[name], so.[name], id.statement , gs.avg_total_user_cost, 
						gs.avg_user_impact, gs.user_seeks, gs.user_scans, gs.unique_compiles,id.equality_columns, 
						id.inequality_columns,id.included_columns
				FROM	sys.dm_db_missing_index_groups ig
						JOIN sys.dm_db_missing_index_details id ON ig.index_handle = id.index_handle
						JOIN sys.dm_db_missing_index_group_stats gs ON ig.index_group_handle = gs.group_handle
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects so on 
							id.object_id=so.object_id
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.schemas sc on 
							so.schema_id=sc.schema_id
				WHERE	id.database_id = ' + CAST(@DatabaseID AS NVARCHAR(30)) + '
				' + CASE WHEN @ObjectID IS NULL THEN N'' 
					ELSE N'and id.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
				END +
		N';'

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);
		INSERT	#MissingIndexes ( [object_id], [database_name], [schema_name], [table_name], [statement], avg_total_user_cost, 
									avg_user_impact, user_seeks, user_scans, unique_compiles, equality_columns, 
									inequality_columns,included_columns)
		EXEC sp_executesql @dsql;

		SET @dsql = N'
			SELECT 
				fk_object.name AS foreign_key_name,
				parent_object.[object_id] AS parent_object_id,
				parent_object.name AS parent_object_name,
				referenced_object.[object_id] AS referenced_object_id,
				referenced_object.name AS referenced_object_name,
				fk.is_disabled,
				fk.is_not_trusted,
				fk.is_not_for_replication,
				parent.fk_columns,
				referenced.fk_columns,
				[update_referential_action_desc],
				[delete_referential_action_desc]
			FROM ' + QUOTENAME(@DatabaseName) + N'.sys.foreign_keys fk
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects fk_object ON fk.object_id=fk_object.object_id
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects parent_object ON fk.parent_object_id=parent_object.object_id
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects referenced_object ON fk.referenced_object_id=referenced_object.object_id
			CROSS APPLY ( SELECT	STUFF( (SELECT	N'', '' + c_parent.name AS fk_columns
											FROM	' + QUOTENAME(@DatabaseName) + N'.sys.foreign_key_columns fkc 
											JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns c_parent ON fkc.parent_object_id=c_parent.[object_id]
												AND fkc.parent_column_id=c_parent.column_id
											WHERE	fk.parent_object_id=fkc.parent_object_id
												AND fk.[object_id]=fkc.constraint_object_id
											ORDER BY fkc.constraint_column_id 
									FOR	  XML PATH('''') ,
											  TYPE).value(''.'', ''varchar(max)''), 1, 1, '''')/*This is how we remove the first comma*/ ) parent ( fk_columns )
			CROSS APPLY ( SELECT	STUFF( (SELECT	N'', '' + c_referenced.name AS fk_columns
											FROM	' + QUOTENAME(@DatabaseName) + N'.sys.	foreign_key_columns fkc 
											JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns c_referenced ON fkc.referenced_object_id=c_referenced.[object_id]
												AND fkc.referenced_column_id=c_referenced.column_id
											WHERE	fk.referenced_object_id=fkc.referenced_object_id
												and fk.[object_id]=fkc.constraint_object_id
											ORDER BY fkc.constraint_column_id  /*order by col name, we don''t have anything better*/
									FOR	  XML PATH('''') ,
											  TYPE).value(''.'', ''varchar(max)''), 1, 1, '''') ) referenced ( fk_columns )
			' + CASE WHEN @ObjectID IS NOT NULL THEN 
					'WHERE fk.parent_object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' OR fk.referenced_object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' 
					ELSE N' ' END + '
			ORDER BY parent_object_name, foreign_key_name;
		';
		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

        RAISERROR (N'Inserting data into #ForeignKeys',0,1) WITH NOWAIT;
        INSERT  #ForeignKeys ( foreign_key_name, parent_object_id,parent_object_name, referenced_object_id, referenced_object_name,
                                is_disabled, is_not_trusted, is_not_for_replication, parent_fk_columns, referenced_fk_columns,
								[update_referential_action_desc], [delete_referential_action_desc] )
                EXEC sp_executesql @dsql;

   
   RAISERROR (N'Updating #IndexSanity.referenced_by_foreign_key',0,1) WITH NOWAIT;
		UPDATE #IndexSanity
			SET is_referenced_by_foreign_key=1
		FROM #IndexSanity s
		JOIN #ForeignKeys fk ON 
			s.object_id=fk.referenced_object_id
			AND LEFT(s.key_column_names,LEN(fk.referenced_fk_columns)) = fk.referenced_fk_columns

		RAISERROR (N'Add computed columns to #IndexSanity to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #IndexSanity ADD 
		[schema_object_name] AS [schema_name] + '.' + [object_name]  ,
		[schema_object_indexid] AS [schema_name] + '.' + [object_name]
			+ CASE WHEN [index_name] IS NOT NULL THEN '.' + index_name
			ELSE ''
			END + ' (' + CAST(index_id AS NVARCHAR(20)) + ')' ,
		first_key_column_name AS CASE	WHEN count_key_columns > 1
			THEN LEFT(key_column_names, CHARINDEX(',', key_column_names, 0) - 1)
			ELSE key_column_names
			END ,
		index_definition AS 
		CASE WHEN partition_key_column_name IS NOT NULL 
			THEN N'[PARTITIONED BY:' + partition_key_column_name +  N']' 
			ELSE '' 
			END +
			CASE index_id
				WHEN 0 THEN N'[HEAP] '
				WHEN 1 THEN N'[CX] '
				ELSE N'' END + CASE WHEN is_indexed_view = 1 THEN '[VIEW] '
				ELSE N'' END + CASE WHEN is_primary_key = 1 THEN N'[PK] '
				ELSE N'' END + CASE WHEN is_XML = 1 THEN N'[XML] '
				ELSE N'' END + CASE WHEN is_spatial = 1 THEN N'[SPATIAL] '
				ELSE N'' END + CASE WHEN is_NC_columnstore = 1 THEN N'[COLUMNSTORE] '
				ELSE N'' END + CASE WHEN is_disabled = 1 THEN N'[DISABLED] '
				ELSE N'' END + CASE WHEN is_hypothetical = 1 THEN N'[HYPOTHETICAL] '
				ELSE N'' END + CASE WHEN is_unique = 1 AND is_primary_key = 0 THEN N'[UNIQUE] '
				ELSE N'' END + CASE WHEN count_key_columns > 0 THEN 
					N'[' + CAST(count_key_columns AS VARCHAR(10)) + N' KEY' 
						+ CASE WHEN count_key_columns > 1 then  N'S' ELSE N'' END
						+ N'] ' + LTRIM(key_column_names_with_sort_order)
				ELSE N'' END + CASE WHEN count_included_columns > 0 THEN 
					N' [' + CAST(count_included_columns AS VARCHAR(10))  + N' INCLUDE' + 
						+ CASE WHEN count_included_columns > 1 then  N'S' ELSE N'' END					
						+ N'] ' + include_column_names
				ELSE N'' END + CASE WHEN filter_definition <> N'' THEN N' [FILTER] ' + filter_definition
				ELSE N'' END ,
		[total_reads] AS user_seeks + user_scans + user_lookups,
		[reads_per_write] AS CAST(CASE WHEN user_updates > 0
			THEN ( user_seeks + user_scans + user_lookups )  / (1.0 * user_updates)
			ELSE 0 END AS MONEY) ,
		[index_usage_summary] AS N'Reads: ' + 
			REPLACE(CONVERT(NVARCHAR(30),CAST((user_seeks + user_scans + user_lookups) AS money), 1), '.00', '')
			+ case when user_seeks + user_scans + user_lookups > 0 then
				N' (' 
					+ RTRIM(
					CASE WHEN user_seeks > 0 then REPLACE(CONVERT(NVARCHAR(30),CAST((user_seeks) AS money), 1), '.00', '') + N' seek ' ELSE N'' END
					+ CASE WHEN user_scans > 0 then REPLACE(CONVERT(NVARCHAR(30),CAST((user_scans) AS money), 1), '.00', '') + N' scan '  ELSE N'' END
					+ CASE WHEN user_lookups > 0 then  REPLACE(CONVERT(NVARCHAR(30),CAST((user_lookups) AS money), 1), '.00', '') + N' lookup' ELSE N'' END
					)
					+ N') '
				else N' ' end 
			+ N'Writes:' + 
			REPLACE(CONVERT(NVARCHAR(30),CAST(user_updates AS money), 1), '.00', ''),
		[more_info] AS N'EXEC dbo.sp_BlitzIndex @DatabaseName=' + QUOTENAME([database_name],'''') + 
			N', @SchemaName=' + QUOTENAME([schema_name],'''') + N', @TableName=' + QUOTENAME([object_name],'''') + N';'

		RAISERROR (N'Update index_secret on #IndexSanity for NC indexes.',0,1) WITH NOWAIT;
		UPDATE nc 
		SET secret_columns=
			N'[' + 
			CASE tb.count_key_columns WHEN 0 THEN '1' ELSE CAST(tb.count_key_columns AS VARCHAR(10)) END +
			CASE nc.is_unique WHEN 1 THEN N' INCLUDE' ELSE N' KEY' END +
			CASE WHEN tb.count_key_columns > 1 then  N'S] ' ELSE N'] ' END +
			CASE tb.index_id WHEN 0 THEN '[RID]' ELSE LTRIM(tb.key_column_names) +
				/* Uniquifiers only needed on non-unique clustereds-- not heaps */
				CASE tb.is_unique WHEN 0 THEN ' [UNIQUIFIER]' ELSE N'' END
			END
			, count_secret_columns=
			CASE tb.index_id WHEN 0 THEN 1 ELSE 
				tb.count_key_columns +
					CASE tb.is_unique WHEN 0 THEN 1 ELSE 0 END
			END
		FROM #IndexSanity AS nc
		JOIN #IndexSanity AS tb ON nc.object_id=tb.object_id
			and tb.index_id in (0,1) 
		WHERE nc.index_id > 1;

		RAISERROR (N'Update index_secret on #IndexSanity for heaps and non-unique clustered.',0,1) WITH NOWAIT;
		UPDATE tb
		SET secret_columns=	CASE tb.index_id WHEN 0 THEN '[RID]' ELSE '[UNIQUIFIER]' END
			, count_secret_columns = 1
		FROM #IndexSanity AS tb
		WHERE tb.index_id = 0 /*Heaps-- these have the RID */
			or (tb.index_id=1 and tb.is_unique=0); /* Non-unique CX: has uniquifer (when needed) */

		RAISERROR (N'Add computed columns to #IndexSanitySize to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #IndexSanitySize ADD 
			  index_size_summary AS ISNULL(
				CASE WHEN partition_count > 1
						THEN N'[' + CAST(partition_count AS NVARCHAR(10)) + N' PARTITIONS] '
						ELSE N''
				END + REPLACE(CONVERT(NVARCHAR(30),CAST([total_rows] AS money), 1), N'.00', N'') + N' rows; '
				+ CASE WHEN total_reserved_MB > 1024 THEN 
					CAST(CAST(total_reserved_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB'
				ELSE 
					CAST(CAST(total_reserved_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB'
				END
				+ CASE WHEN total_reserved_LOB_MB > 1024 THEN 
					N'; ' + CAST(CAST(total_reserved_LOB_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB LOB'
				WHEN total_reserved_LOB_MB > 0 THEN
					N'; ' + CAST(CAST(total_reserved_LOB_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB LOB'
				ELSE ''
				END
				 + CASE WHEN total_reserved_row_overflow_MB > 1024 THEN
					N'; ' + CAST(CAST(total_reserved_row_overflow_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB Row Overflow'
				WHEN total_reserved_row_overflow_MB > 0 THEN
					N'; ' + CAST(CAST(total_reserved_row_overflow_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB Row Overflow'
				ELSE ''
				END ,
					N'Error- NULL in computed column'),
			index_op_stats AS ISNULL(
				(
					REPLACE(CONVERT(NVARCHAR(30),CAST(total_singleton_lookup_count AS MONEY), 1),N'.00',N'') + N' singleton lookups; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_range_scan_count AS MONEY), 1),N'.00',N'') + N' scans/seeks; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_leaf_delete_count AS MONEY), 1),N'.00',N'') + N' deletes; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_leaf_update_count AS MONEY), 1),N'.00',N'') + N' updates; '
					+ CASE WHEN ISNULL(total_forwarded_fetch_count,0) >0 THEN
						REPLACE(CONVERT(NVARCHAR(30),CAST(total_forwarded_fetch_count AS MONEY), 1),N'.00',N'') + N' forward records fetched; '
					ELSE N'' END

					/* rows will only be in this dmv when data is in memory for the table */
				), N'Table metadata not in memory'),
			index_lock_wait_summary AS ISNULL(
				CASE WHEN total_row_lock_wait_count = 0 and  total_page_lock_wait_count = 0 and
					total_index_lock_promotion_attempt_count = 0 THEN N'0 lock waits.'
				ELSE
					CASE WHEN total_row_lock_wait_count > 0 THEN
						N'Row lock waits: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_row_lock_wait_count AS money), 1), N'.00', N'')
						+ N'; total duration: ' + 
							CASE WHEN total_row_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((total_row_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_row_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
						+ N'avg duration: ' + 
							CASE WHEN avg_row_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((avg_row_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(avg_row_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
					ELSE N''
					END +
					CASE WHEN total_page_lock_wait_count > 0 THEN
						N'Page lock waits: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_page_lock_wait_count AS money), 1), N'.00', N'')
						+ N'; total duration: ' + 
							CASE WHEN total_page_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((total_page_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_page_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
						+ N'avg duration: ' + 
							CASE WHEN avg_page_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((avg_page_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(avg_page_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
					ELSE N''
					END +
					CASE WHEN total_index_lock_promotion_attempt_count > 0 THEN
						N'Lock escalation attempts: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_index_lock_promotion_attempt_count AS money), 1), N'.00', N'')
						+ N'; Actual Escalations: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_index_lock_promotion_count,0) AS money), 1), N'.00', N'') + N'.'
					ELSE N''
					END
				END                  
					,'Error- NULL in computed column')


		RAISERROR (N'Add computed columns to #missing_index to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #MissingIndexes ADD 
				[index_estimated_impact] AS 
					CAST(user_seeks + user_scans AS NVARCHAR(30)) + N' use' 
						+ CASE WHEN (user_seeks + user_scans) > 1 THEN N's' ELSE N'' END
						 +N'; Impact: ' + CAST(avg_user_impact AS NVARCHAR(30))
						+ N'%; Avg query cost: '
						+ CAST(avg_total_user_cost AS NVARCHAR(30)),
				[missing_index_details] AS
					CASE WHEN equality_columns IS NOT NULL THEN N'EQUALITY: ' + equality_columns + N' '
						 ELSE N''
					END + CASE WHEN inequality_columns IS NOT NULL THEN N'INEQUALITY: ' + inequality_columns + N' '
					   ELSE N''
					END + CASE WHEN included_columns IS NOT NULL THEN N'INCLUDES: ' + included_columns + N' '
						ELSE N''
					END,
				[create_tsql] AS N'CREATE INDEX [ix_' + table_name + N'_' 
					+ REPLACE(REPLACE(REPLACE(REPLACE(
						ISNULL(equality_columns,N'')+ 
						CASE when equality_columns is not null and inequality_columns is not null then N'_' else N'' END
						+ ISNULL(inequality_columns,''),',','')
						,'[',''),']',''),' ','_') 
					+ CASE WHEN included_columns IS NOT NULL THEN N'_includes' ELSE N'' END + N'] ON ' 
					+ [statement] + N' (' + ISNULL(equality_columns,N'')
					+ CASE WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN N', ' ELSE N'' END
					+ CASE WHEN inequality_columns IS NOT NULL THEN inequality_columns ELSE N'' END + 
					') ' + CASE WHEN included_columns IS NOT NULL THEN N' INCLUDE (' + included_columns + N')' ELSE N'' END
					+ N' WITH (' 
						+ N'FILLFACTOR=100, ONLINE=?, SORT_IN_TEMPDB=?' 
					+ N')'
					+ N';'
					,
				[more_info] AS N'EXEC dbo.sp_BlitzIndex @DatabaseName=' + QUOTENAME([database_name],'''') + 
					N', @SchemaName=' + QUOTENAME([schema_name],'''') + N', @TableName=' + QUOTENAME([table_name],'''') + N';'
				;


		RAISERROR (N'Populate #IndexCreateTsql.',0,1) WITH NOWAIT;
		INSERT #IndexCreateTsql (index_sanity_id, create_tsql)
		SELECT
			index_sanity_id,
			ISNULL (
			/* Script drops for disabled non-clustered indexes*/
			CASE WHEN is_disabled = 1 AND index_id <> 1
				THEN N'--DROP INDEX ' + QUOTENAME([index_name]) + N' ON '
				 + QUOTENAME([schema_name]) + N'.' + QUOTENAME([object_name]) 
			ELSE
				CASE index_id WHEN 0 THEN N'--I''m a Heap!' 
				ELSE 
					CASE WHEN is_XML = 1 OR is_spatial=1 THEN N'' /* Not even trying for these just yet...*/
					ELSE 
						CASE WHEN is_primary_key=1 THEN
							N'ALTER TABLE ' + QUOTENAME([schema_name]) +
								N'.' + QUOTENAME([object_name]) + 
								N' ADD CONSTRAINT [' +
								index_name + 
								N'] PRIMARY KEY ' + 
								CASE WHEN index_id=1 THEN N'CLUSTERED (' ELSE N'(' END +
								key_column_names_with_sort_order_no_types + N' )' 
							WHEN is_CX_columnstore= 1 THEN
								 N'CREATE CLUSTERED COLUMNSTORE INDEX ' + QUOTENAME(index_name) + N' on ' + QUOTENAME([schema_name]) + '.' + QUOTENAME([object_name])
						ELSE /*Else not a PK or cx columnstore */ 
							N'CREATE ' + 
							CASE WHEN is_unique=1 THEN N'UNIQUE ' ELSE N'' END +
							CASE WHEN index_id=1 THEN N'CLUSTERED ' ELSE N'' END +
							CASE WHEN is_NC_columnstore=1 THEN N'NONCLUSTERED COLUMNSTORE ' 
							ELSE N'' END +
							N'INDEX ['
								 + index_name + N'] ON ' + 
								QUOTENAME([schema_name]) + '.' + QUOTENAME([object_name]) + 
									CASE WHEN is_NC_columnstore=1 THEN 
										N' (' + ISNULL(include_column_names_no_types,'') +  N' )' 
									ELSE /*Else not colunnstore */ 
										N' (' + ISNULL(key_column_names_with_sort_order_no_types,'') +  N' )' 
										+ CASE WHEN include_column_names_no_types IS NOT NULL THEN 
											N' INCLUDE (' + include_column_names_no_types + N')' 
											ELSE N'' 
										END
									END /*End non-colunnstore case */ 
								+ CASE WHEN filter_definition <> N'' THEN N' WHERE ' + filter_definition ELSE N'' END
							END /*End Non-PK index CASE */ 
						+ CASE WHEN is_NC_columnstore=0 and is_CX_columnstore=0 then
							N' WITH (' 
								+ N'FILLFACTOR=' + CASE fill_factor when 0 then N'100' else CAST(fill_factor AS NVARCHAR(5)) END + ', '
								+ N'ONLINE=?, SORT_IN_TEMPDB=?'
							+ N')'
						else N'' end
						+ N';'
  					END /*End non-spatial and non-xml CASE */ 
				END
			END, '[Unknown Error]')
				AS create_tsql
		FROM #IndexSanity;
					
	END
END TRY
BEGIN CATCH
		RAISERROR (N'Failure populating temp tables.', 0,1) WITH NOWAIT;

		IF @dsql IS NOT NULL
		BEGIN
			SET @msg= 'Last @dsql: ' + @dsql;
			RAISERROR(@msg, 0, 1) WITH NOWAIT;
		END

		SELECT	@msg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RAISERROR (@msg,@ErrorSeverity, @ErrorState )WITH NOWAIT;
		
		
		WHILE @@trancount > 0 
			ROLLBACK;

		RETURN;
END CATCH;

----------------------------------------
--STEP 2: DIAGNOSE THE PATIENT
--EVERY QUERY AFTER THIS GOES AGAINST TEMP TABLES ONLY.
----------------------------------------
BEGIN TRY
----------------------------------------
--If @TableName is specified, just return information for that table.
--The @Mode parameter doesn't matter if you're looking at a specific table.
----------------------------------------
IF @TableName IS NOT NULL
BEGIN
	RAISERROR(N'@TableName specified, giving detail only on that table.', 0,1) WITH NOWAIT;

	--We do a left join here in case this is a disabled NC.
	--In that case, it won't have any size info/pages allocated.
	WITH table_mode_cte AS (
		SELECT 
			s.schema_object_indexid, 
			s.key_column_names,
			s.index_definition, 
			ISNULL(s.secret_columns,N'') AS secret_columns,
			s.fill_factor,
			s.index_usage_summary, 
			sz.index_op_stats,
			ISNULL(sz.index_size_summary,'') /*disabled NCs will be null*/ AS index_size_summary,
			ISNULL(sz.index_lock_wait_summary,'') AS index_lock_wait_summary,
			s.is_referenced_by_foreign_key,
			(SELECT COUNT(*)
				FROM #ForeignKeys fk WHERE fk.parent_object_id=s.object_id
				AND PATINDEX (fk.parent_fk_columns, s.key_column_names)=1) AS FKs_covered_by_index,
			s.last_user_seek,
			s.last_user_scan,
			s.last_user_lookup,
			s.last_user_update,
			s.create_date,
			s.modify_date,
			ct.create_tsql,
			1 as display_order
		FROM #IndexSanity s
		LEFT JOIN #IndexSanitySize sz ON 
			s.index_sanity_id=sz.index_sanity_id
		LEFT JOIN #IndexCreateTsql ct ON 
			s.index_sanity_id=ct.index_sanity_id
		WHERE s.[object_id]=@ObjectID
		UNION ALL
		SELECT 	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121) + 			
				N' (sp_BlitzIndex(TM) v2.02 - Jan 30, 2014)' ,   
				N'From Brent Ozar Unlimited(TM)' ,   
				N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				0 as display_order
	)
	SELECT 
			schema_object_indexid AS [Details: schema.table.index(indexid)], 
			index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}], 
			secret_columns AS [Secret Columns],
			fill_factor AS [Fillfactor],
			index_usage_summary AS [Usage Stats], 
			index_op_stats as [Op Stats],
			index_size_summary AS [Size],
			index_lock_wait_summary AS [Lock Waits],
			is_referenced_by_foreign_key AS [Referenced by FK?],
			FKs_covered_by_index AS [FK Covered by Index?],
			last_user_seek AS [Last User Seek],
			last_user_scan AS [Last User Scan],
			last_user_lookup AS [Last User Lookup],
			last_user_update as [Last User Write],
			create_date AS [Created],
			modify_date AS [Last Modified],
			create_tsql AS [Create TSQL]
	FROM table_mode_cte
	ORDER BY display_order ASC, key_column_names ASC
	OPTION	( RECOMPILE );						

	IF (SELECT TOP 1 [object_id] FROM    #MissingIndexes mi) IS NOT NULL
	BEGIN  
		SELECT  N'Missing index.' AS Finding ,
				N'http://BrentOzar.com/go/Indexaphobia' AS URL ,
				mi.[statement] + ' Est Benefit: '
					+ CASE WHEN magic_benefit_number >= 922337203685477 THEN '>= 922,337,203,685,477'
					ELSE REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(magic_benefit_number AS BIGINT) AS money), 1), '.00', '')
					END AS [Estimated Benefit],
				missing_index_details AS [Missing Index Request] ,
				index_estimated_impact AS [Estimated Impact],
				create_tsql AS [Create TSQL]
		FROM    #MissingIndexes mi
		WHERE   [object_id] = @ObjectID
		ORDER BY magic_benefit_number DESC
		OPTION	( RECOMPILE );
	END       
	ELSE     
	SELECT 'No missing indexes.' AS finding;

	SELECT 	
		column_name AS [Column Name],
		(SELECT COUNT(*)  
			FROM #IndexColumns c2 
			WHERE c2.column_name=c.column_name
			and c2.key_ordinal is not null)
		+ CASE WHEN c.index_id = 1 and c.key_ordinal is not null THEN
			-1+ (SELECT COUNT(DISTINCT index_id)
			from #IndexColumns c3
			where c3.index_id not in (0,1))
			ELSE 0 END
				AS [Found In],
		system_type_name + 
			CASE max_length WHEN -1 THEN N' (max)' ELSE
				CASE  
					WHEN system_type_name in (N'char',N'nchar',N'binary',N'varbinary') THEN N' (' + CAST(max_length as NVARCHAR(20)) + N')' 
					WHEN system_type_name in (N'varchar',N'nvarchar') THEN N' (' + CAST(max_length/2 as NVARCHAR(20)) + N')' 
					ELSE '' 
				END
			END
			AS [Type],
		CASE is_computed WHEN 1 THEN 'yes' ELSE '' END AS [Computed?],
		max_length AS [Length (max bytes)],
		[precision] AS [Prec],
		[scale] AS [Scale],
		CASE is_nullable WHEN 1 THEN 'yes' ELSE '' END AS [Nullable?],
		CASE is_identity WHEN 1 THEN 'yes' ELSE '' END AS [Identity?],
		CASE is_replicated WHEN 1 THEN 'yes' ELSE '' END AS [Replicated?],
		CASE is_sparse WHEN 1 THEN 'yes' ELSE '' END AS [Sparse?],
		CASE is_filestream WHEN 1 THEN 'yes' ELSE '' END AS [Filestream?],
		collation_name AS [Collation]
	FROM #IndexColumns AS c
	where index_id in (0,1);

	IF (SELECT TOP 1 parent_object_id FROM #ForeignKeys) IS NOT NULL
	BEGIN
		SELECT parent_object_name + N': ' + foreign_key_name AS [Foreign Key],
			parent_fk_columns AS [Foreign Key Columns],
			referenced_object_name AS [Referenced Table],
			referenced_fk_columns AS [Referenced Table Columns],
			is_disabled AS [Is Disabled?],
			is_not_trusted as [Not Trusted?],
			is_not_for_replication [Not for Replication?],
			[update_referential_action_desc] as [Cascading Updates?],
			[delete_referential_action_desc] as [Cascading Deletes?]
		FROM #ForeignKeys
		ORDER BY [Foreign Key]
		OPTION	( RECOMPILE );
	END
	ELSE
	SELECT 'No foreign keys.' AS finding;
END 

--If @TableName is NOT specified...
--Act based on the @Mode and @Filter. (@Filter applies only when @Mode=0 "diagnose")
ELSE
BEGIN;
	IF @Mode=0 /* DIAGNOSE*/
	BEGIN;
		RAISERROR(N'@Mode=0, we are diagnosing.', 0,1) WITH NOWAIT;

	-- choi bo ra 주석 처리
	/*	RAISERROR(N'Insert a row to help people find help', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,
										index_usage_summary, index_size_summary )
		VALUES  ( 0 , 
				N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121), 
				N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,
				N'From Brent Ozar Unlimited(TM)' ,   N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
				, N'',N''
				);
  */

  
		----------------------------------------
		--Multiple Index Personalities: Check_id 0-10
		----------------------------------------
		BEGIN;
		RAISERROR('check_id 1: Duplicate keys', 0,1) WITH NOWAIT;
			WITH	duplicate_indexes
					  AS ( SELECT	[object_id], key_column_names
						   FROM		#IndexSanity
						   WHERE  index_type IN (1,2) /* Clustered, NC only*/
								AND is_hypothetical = 0
								AND is_disabled = 0
						   GROUP BY	[object_id], key_column_names
						   HAVING	COUNT(*) > 1)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	1 AS check_id, 
								ip.index_sanity_id,
								'Multiple Index Personalities' AS findings_group,
								'Duplicate keys' AS finding,
								N'http://BrentOzar.com/go/duplicateindex' AS URL,
								ip.schema_object_indexid AS details,
								ip.index_definition, 
								ip.secret_columns, 
								ip.index_usage_summary,
								ips.index_size_summary
						FROM	duplicate_indexes di
								JOIN #IndexSanity ip ON di.[object_id] = ip.[object_id]
														 AND ip.key_column_names = di.key_column_names
								JOIN #IndexSanitySize ips ON ip.index_sanity_id = ips.index_sanity_id
						ORDER BY ip.object_id, ip.key_column_names_with_sort_order	
				OPTION	( RECOMPILE );

		RAISERROR('check_id 2: Keys w/ identical leading columns.', 0,1) WITH NOWAIT;
			WITH	borderline_duplicate_indexes
					  AS ( SELECT DISTINCT [object_id], first_key_column_name, key_column_names,
									COUNT([object_id]) OVER ( PARTITION BY [object_id], first_key_column_name ) AS number_dupes
						   FROM		#IndexSanity
						   WHERE index_type IN (1,2) /* Clustered, NC only*/
							AND is_hypothetical=0
							AND is_disabled=0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id,  findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	2 AS check_id, 
								ip.index_sanity_id,
								'Multiple Index Personalities' AS findings_group,
								'Borderline duplicate keys' AS finding,
								N'http://BrentOzar.com/go/duplicateindex' AS URL,
								ip.schema_object_indexid AS details, 
								ip.index_definition, 
								ip.secret_columns,
								ip.index_usage_summary,
								ips.index_size_summary
						FROM	#IndexSanity AS ip 
						JOIN #IndexSanitySize ips ON ip.index_sanity_id = ips.index_sanity_id
						WHERE EXISTS (
							SELECT di.[object_id]
							FROM borderline_duplicate_indexes AS di
							WHERE di.[object_id] = ip.[object_id] AND
								di.first_key_column_name = ip.first_key_column_name AND
								di.key_column_names <> ip.key_column_names AND
								di.number_dupes > 1	
						)
						ORDER BY ip.[schema_name], ip.[object_name], ip.key_column_names, ip.include_column_names
			OPTION	( RECOMPILE );

		END
		----------------------------------------
		--Aggressive Indexes: Check_id 10-19
		----------------------------------------
		BEGIN;

		RAISERROR(N'check_id 11: Total lock wait time > 5 minutes (row + page)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										secret_columns, index_usage_summary, index_size_summary )
				SELECT	11 AS check_id, 
						i.index_sanity_id,
						N'Aggressive Indexes' AS findings_group,
						N'Total lock wait time > 5 minutes (row + page)' AS finding, 
						N'http://BrentOzar.com/go/AggressiveIndexes' AS URL,
						i.schema_object_indexid + N': ' +
							sz.index_lock_wait_summary AS details, 
						i.index_definition,
						i.secret_columns,
						i.index_usage_summary,
						sz.index_size_summary
				FROM	#IndexSanity AS i
				JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
				WHERE	(total_row_lock_wait_in_ms + total_page_lock_wait_in_ms) > 300000
				OPTION	( RECOMPILE );
		END

		---------------------------------------- 
		--Index Hoarder: Check_id 20-29
		----------------------------------------
		BEGIN
			RAISERROR(N'check_id 20: >=7 NC indexes on any given table. Yes, 7 is an arbitrary number.', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	20 AS check_id, 
								MAX(i.index_sanity_id) AS index_sanity_id, 
								'Index Hoarder' AS findings_group,
								'Many NC indexes on a single table' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								CAST (COUNT(*) AS NVARCHAR(30)) + ' NC indexes on ' + i.schema_object_name AS details,
								i.schema_object_name + ' (' + CAST (COUNT(*) AS NVARCHAR(30)) + ' indexes)' AS index_definition,
								'' AS secret_columns,
								REPLACE(CONVERT(NVARCHAR(30),CAST(SUM(total_reads) AS money), 1), N'.00', N'') + N' reads (ALL); '
									+ REPLACE(CONVERT(NVARCHAR(30),CAST(SUM(user_updates) AS money), 1), N'.00', N'') + N' writes (ALL); ',
								REPLACE(CONVERT(NVARCHAR(30),CAST(MAX(total_rows) AS money), 1), N'.00', N'') + N' rows (MAX)'
									+ CASE WHEN SUM(total_reserved_MB) > 1024 THEN 
										N'; ' + CAST(CAST(SUM(total_reserved_MB)/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'GB (ALL)'
									WHEN SUM(total_reserved_MB) > 0 THEN
										N'; ' + CAST(CAST(SUM(total_reserved_MB) AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'MB (ALL)'
									ELSE ''
									END AS index_size_summary
						FROM	#IndexSanity i
						JOIN #IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	index_id NOT IN ( 0, 1 )
						GROUP BY schema_object_name
						HAVING	COUNT(*) >= 7
						ORDER BY i.schema_object_name DESC  OPTION	( RECOMPILE );

			if @Filter = 1 /*@Filter=1 is "ignore unusued" */
			BEGIN
				RAISERROR(N'Skipping checks on unused indexes (21 and 22) because @Filter=1', 0,1) WITH NOWAIT;
			END
			ELSE /*Otherwise, go ahead and do the checks*/
			BEGIN
				RAISERROR(N'check_id 21: >=5 percent of indexes are unused. Yes, 5 is an arbitrary number.', 0,1) WITH NOWAIT;
					DECLARE @percent_NC_indexes_unused NUMERIC(29,1);
					DECLARE @NC_indexes_unused_reserved_MB NUMERIC(29,1);

					SELECT	@percent_NC_indexes_unused =( 100.00 * SUM(CASE	WHEN total_reads = 0 THEN 1
												ELSE 0
										   END) ) / COUNT(*) ,
							@NC_indexes_unused_reserved_MB = SUM(CASE WHEN total_reads = 0 THEN sz.total_reserved_MB
									 ELSE 0
								END) 
					FROM	#IndexSanity i
					JOIN	#IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id NOT IN ( 0, 1 ) 
							and i.is_unique = 0
					OPTION	( RECOMPILE );

				IF @percent_NC_indexes_unused >= 5 
					INSERT	#BlitzIndexResults ( check_id, index_sanity_id,  findings_group, finding, URL, details, index_definition,
												   secret_columns, index_usage_summary, index_size_summary )
							SELECT	21 AS check_id, 
									MAX(i.index_sanity_id) AS index_sanity_id, 
									N'Index Hoarder' AS findings_group,
									N'More than 5 percent NC indexes are unused' AS finding,
									N'http://BrentOzar.com/go/IndexHoarder' AS URL,
									CAST (@percent_NC_indexes_unused AS NVARCHAR(30)) + N' percent NC indexes (' + CAST(COUNT(*) AS NVARCHAR(10)) + N') unused. ' +
									N'These take up ' + CAST (@NC_indexes_unused_reserved_MB AS NVARCHAR(30)) + N'MB of space.' AS details,
									i.database_name + ' (' + CAST (COUNT(*) AS NVARCHAR(30)) + N' indexes)' AS index_definition,
									'' AS secret_columns, 
									CAST(SUM(total_reads) AS NVARCHAR(256)) + N' reads (ALL); '
										+ CAST(SUM([user_updates]) AS NVARCHAR(256)) + N' writes (ALL)' AS index_usage_summary,
								
									REPLACE(CONVERT(NVARCHAR(30),CAST(MAX([total_rows]) AS money), 1), '.00', '') + N' rows (MAX)'
										+ CASE WHEN SUM(total_reserved_MB) > 1024 THEN 
											N'; ' + CAST(CAST(SUM(total_reserved_MB)/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'GB (ALL)'
										WHEN SUM(total_reserved_MB) > 0 THEN
											N'; ' + CAST(CAST(SUM(total_reserved_MB) AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'MB (ALL)'
										ELSE ''
										END AS index_size_summary
							FROM	#IndexSanity i
							JOIN	#IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
							WHERE	index_id NOT IN ( 0, 1 )
									AND i.is_unique = 0
									AND total_reads = 0
							GROUP BY i.database_name 
					OPTION	( RECOMPILE );

				RAISERROR(N'check_id 22: NC indexes with 0 reads. (Borderline)', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	22 AS check_id, 
								i.index_sanity_id,
								N'Index Hoarder' AS findings_group,
								N'Unused NC index' AS finding, 
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								N'0 reads: ' + i.schema_object_indexid AS details, 
								i.index_definition, 
								i.secret_columns, 
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity AS i
						JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.total_reads=0
								AND i.index_id NOT IN (0,1) /*NCs only*/
								and i.is_unique = 0
						ORDER BY i.schema_object_indexid
						OPTION	( RECOMPILE );
			END /*end checks only run when @Filter <> 1*/

			RAISERROR(N'check_id 23: Indexes with 7 or more columns. (Borderline)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	23 AS check_id, 
							i.index_sanity_id, 
							N'Index Hoarder' AS findings_group,
							N'Borderline: Wide indexes (7 or more columns)' AS finding, 
							N'http://BrentOzar.com/go/IndexHoarder' AS URL,
							CAST(count_key_columns + count_included_columns AS NVARCHAR(10)) + ' columns on '
							+ i.schema_object_indexid AS details, i.index_definition, 
							i.secret_columns, 
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	( count_key_columns + count_included_columns ) >= 7
					OPTION	( RECOMPILE );

			RAISERROR(N'check_id 24: Wide clustered indexes (> 3 columns or > 16 bytes).', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE max_length when -1 THEN 0 ELSE max_length END) AS sum_max_length
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							and key_ordinal > 0
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	24 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Wide clustered index (> 3 columns OR > 16 bytes)' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								CAST (i.count_key_columns AS NVARCHAR(10)) + N' columns with potential size of '
									+ CAST(cc.sum_max_length AS NVARCHAR(10))
									+ N' bytes in clustered index:' + i.schema_object_name 
									+ N'. ' + 
										(SELECT CAST(COUNT(*) AS NVARCHAR(23)) FROM #IndexSanity i2 
										WHERE i2.[object_id]=i.[object_id] AND i2.index_id <> 1
										AND i2.is_disabled=0 AND i2.is_hypothetical=0)
										+ N' NC indexes on the table.'
									AS details,
								i.index_definition,
								secret_columns, 
								i.index_usage_summary,
								ip.index_size_summary
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]	
						WHERE	index_id = 1 /* clustered only */
								AND 
									(count_key_columns > 3 /*More than three key columns.*/
									OR cc.sum_max_length > 15 /*More than 16 bytes in key */)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 25: Addicted to nullable columns.', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE is_nullable WHEN 1 THEN 0 ELSE 1 END) as non_nullable_columns,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	25 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Addicted to nulls' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' allows null in ' + CAST((total_columns-non_nullable_columns) as NVARCHAR(10))
									+ N' of ' + CAST(total_columns as NVARCHAR(10))
									+ N' columns.' AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							AND cc.non_nullable_columns < 2
							and cc.total_columns > 3
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 26: Wide tables (35+ cols or > 2000 non-LOB bytes).', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE max_length when -1 THEN 1 ELSE 0 END) AS count_lob_columns,
								SUM(CASE max_length when -1 THEN 0 ELSE max_length END) AS sum_max_length,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	26 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Wide tables: 35+ cols or > 2000 non-LOB bytes' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST((total_columns) as NVARCHAR(10))
									+ N' total columns with a max possible width of ' + CAST(sum_max_length as NVARCHAR(10))
									+ N' bytes.' +
									CASE WHEN count_lob_columns > 0 THEN CAST((count_lob_columns) as NVARCHAR(10))
										+ ' columns are LOB types.' ELSE ''
									END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							and 
							(cc.total_columns >= 35 OR
							cc.sum_max_length >= 2000)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );
					
			RAISERROR(N'check_id 27: Addicted to strings.', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE WHEN system_type_name in ('varchar','nvarchar','char') or max_length=-1 THEN 1 ELSE 0 END) as string_or_LOB_columns,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	27 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Addicted to strings' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' uses string or LOB types for ' + CAST((string_or_LOB_columns) as NVARCHAR(10))
									+ N' of ' + CAST(total_columns as NVARCHAR(10))
									+ N' columns. Check if data types are valid.' AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						CROSS APPLY (SELECT cc.total_columns - string_or_LOB_columns AS non_string_or_lob_columns) AS calc1
						WHERE	i.index_id in (1,0)
							AND calc1.non_string_or_lob_columns <= 1
							AND cc.total_columns > 3
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 28: Non-unique clustered index.', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	28 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Non-Unique clustered index' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								N'Uniquifiers will be required! Clustered index: ' + i.schema_object_name 
									+ N' and all NC indexes. ' + 
										(SELECT CAST(COUNT(*) AS NVARCHAR(23)) FROM #IndexSanity i2 
										WHERE i2.[object_id]=i.[object_id] AND i2.index_id <> 1
										AND i2.is_disabled=0 AND i2.is_hypothetical=0)
										+ N' NC indexes on the table.'
									AS details,
								i.index_definition,
								secret_columns, 
								i.index_usage_summary,
								ip.index_size_summary
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	index_id = 1 /* clustered only */
								AND is_unique=0 /* not unique */
								AND is_CX_columnstore=0 /* not a clustered columnstore-- no unique option on those */
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );


		END
		 ----------------------------------------
		--Feature-Phobic Indexes: Check_id 30-39
		---------------------------------------- 
		BEGIN
			RAISERROR(N'check_id 30: No indexes with includes', 0,1) WITH NOWAIT;

			DECLARE	@number_indexes_with_includes INT;
			DECLARE	@percent_indexes_with_includes NUMERIC(10, 1);

			SELECT	@number_indexes_with_includes = SUM(CASE WHEN count_included_columns > 0 THEN 1 ELSE 0	END),
					@percent_indexes_with_includes = 100.* 
						SUM(CASE WHEN count_included_columns > 0 THEN 1 ELSE 0 END) / ( 1.0 * COUNT(*) )
			FROM	#IndexSanity;

			IF @number_indexes_with_includes = 0 
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	30 AS check_id, 
								NULL AS index_sanity_id, 
								N'Feature-Phobic Indexes' AS findings_group,
								N'No indexes use includes' AS finding, 'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'No indexes use includes' AS details,
								N'Entire database' AS index_definition, 
								N'' AS secret_columns, 
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );

			RAISERROR(N'check_id 31: < 3 percent of indexes have includes', 0,1) WITH NOWAIT;
			IF @percent_indexes_with_includes <= 3 AND @number_indexes_with_includes > 0 
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	31 AS check_id,
								NULL AS index_sanity_id, 
								N'Feature-Phobic Indexes' AS findings_group,
								N'Borderline: Includes are used in < 3% of indexes' AS findings,
								N'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'Only ' + CAST(@percent_indexes_with_includes AS NVARCHAR(10)) + '% of indexes have includes' AS details, 
								N'Entire database' AS index_definition, 
								N'' AS secret_columns,
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );

			RAISERROR(N'check_id 32: filtered indexes and indexed views', 0,1) WITH NOWAIT;
			DECLARE @count_filtered_indexes INT;
			DECLARE @count_indexed_views INT;

				SELECT	@count_filtered_indexes=COUNT(*)
				FROM	#IndexSanity
				WHERE	filter_definition <> '' OPTION	( RECOMPILE );

				SELECT	@count_indexed_views=COUNT(*)
				FROM	#IndexSanity AS i
						JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
				WHERE	is_indexed_view = 1 OPTION	( RECOMPILE );

			IF @count_filtered_indexes = 0 AND @count_indexed_views=0
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	32 AS check_id, 
								NULL AS index_sanity_id,
								N'Feature-Phobic Indexes' AS findings_group,
								N'Borderline: No filtered indexes or indexed views exist' AS finding, 
								N'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'These are NOT always needed-- but do you know when you would use them?' AS details,
								N'Entire database' AS index_definition, 
								N'' AS secret_columns,
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );
		END;

		RAISERROR(N'check_id 33: Potential filtered indexes based on column names.', 0,1) WITH NOWAIT;

		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										secret_columns, index_usage_summary, index_size_summary )
		SELECT	33 AS check_id, 
				i.index_sanity_id AS index_sanity_id,
				N'Feature-Phobic Indexes' AS findings_group,
				N'Potential filtered index (based on column name)' AS finding, 
				N'http://BrentOzar.com/go/IndexFeatures' AS URL,
				N'A column name in this index suggests it might be a candidate for filtering (is%, %archive%, %active%, %flag%)' AS details,
				i.index_definition, 
				i.secret_columns,
				i.index_usage_summary, 
				sz.index_size_summary
		FROM #IndexColumns ic 
		join #IndexSanity i on 
			ic.[object_id]=i.[object_id] and
			ic.[index_id]=i.[index_id] and
			i.[index_id] > 1 /* non-clustered index */
		JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
		WHERE column_name like 'is%'
			or column_name like '%archive%'
			or column_name like '%active%'
			or column_name like '%flag%'
		OPTION	( RECOMPILE );

		 ----------------------------------------
		--Self Loathing Indexes : Check_id 40-49
		----------------------------------------
		BEGIN

			RAISERROR(N'check_id 40: Fillfactor in nonclustered 80 percent or less', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	40 AS check_id, 
							i.index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Low Fill Factor: nonclustered index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Fill factor on ' + schema_object_indexid + N' is ' + CAST(fill_factor AS NVARCHAR(10)) + N'%. '+
								CASE WHEN (last_user_update is null OR user_updates < 1)
								THEN N'No writes have been made.'
								ELSE
									N'Last write was ' +  CONVERT(NVARCHAR(16),last_user_update,121) + N' and ' + 
									CAST(user_updates as NVARCHAR(25)) + N' updates have been made.'
								END
								AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id > 1
					and	fill_factor BETWEEN 1 AND 80 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 40: Fillfactor in clustered 90 percent or less', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	40 AS check_id, 
							i.index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Low Fill Factor: clustered index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Fill factor on ' + schema_object_indexid + N' is ' + CAST(fill_factor AS NVARCHAR(10)) + N'%. '+
								CASE WHEN (last_user_update is null OR user_updates < 1)
								THEN N'No writes have been made.'
								ELSE
									N'Last write was ' +  CONVERT(NVARCHAR(16),last_user_update,121) + N' and ' + 
									CAST(user_updates as NVARCHAR(25)) + N' updates have been made.'
								END
								AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id = 1
					and fill_factor BETWEEN 1 AND 90 OPTION	( RECOMPILE );


			RAISERROR(N'check_id 41: Hypothetical indexes ', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	41 AS check_id, 
							N'Self Loathing Indexes' AS findings_group,
							N'Hypothetical Index' AS finding, 'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Hypothetical Index: ' + schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							N'' AS index_usage_summary, 
							N'' AS index_size_summary
					FROM	#IndexSanity AS i
					WHERE	is_hypothetical = 1 OPTION	( RECOMPILE );


			RAISERROR(N'check_id 42: Disabled indexes', 0,1) WITH NOWAIT;
			--Note: disabled NC indexes will have O rows in #IndexSanitySize!
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	42 AS check_id, 
							index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Disabled Index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Disabled Index:' + schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							'DISABLED' AS index_size_summary
					FROM	#IndexSanity AS i
					WHERE	is_disabled = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 43: Heaps with forwarded records or deletes', 0,1) WITH NOWAIT;
			WITH	heaps_cte
					  AS ( SELECT	[object_id], 
									SUM(forwarded_fetch_count) AS forwarded_fetch_count,
									SUM(leaf_delete_count) AS leaf_delete_count
						   FROM		#IndexPartitionSanity
						   GROUP BY	[object_id]
						   HAVING	SUM(forwarded_fetch_count) > 0
									OR SUM(leaf_delete_count) > 0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	43 AS check_id, 
								i.index_sanity_id,
								N'Self Loathing Indexes' AS findings_group,
								N'Heaps with forwarded records or deletes' AS finding, 
								N'http://BrentOzar.com/go/SelfLoathing' AS URL,
								CAST(h.forwarded_fetch_count AS NVARCHAR(256)) + ' forwarded fetches, '
								+ CAST(h.leaf_delete_count AS NVARCHAR(256)) + ' deletes against heap:'
								+ schema_object_indexid AS details, 
								i.index_definition, 
								i.secret_columns,
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity i
						JOIN heaps_cte h ON i.[object_id] = h.[object_id]
						JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.index_id = 0 
				OPTION	( RECOMPILE );

			RAISERROR(N'check_id 44: Heaps with reads or writes.', 0,1) WITH NOWAIT;
			WITH	heaps_cte
					  AS ( SELECT	[object_id], SUM(forwarded_fetch_count) AS forwarded_fetch_count,
									SUM(leaf_delete_count) AS leaf_delete_count
						   FROM		#IndexPartitionSanity
						   GROUP BY	[object_id]
						   HAVING	SUM(forwarded_fetch_count) > 0
									OR SUM(leaf_delete_count) > 0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	44 AS check_id, 
								i.index_sanity_id,
								N'Self Loathing Indexes' AS findings_group,
								N'Active heap' AS finding, 
								N'http://BrentOzar.com/go/SelfLoathing' AS URL,
								N'Should this table be a heap? ' + schema_object_indexid AS details, 
								i.index_definition, 
								'N/A' AS secret_columns,
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity i
						LEFT JOIN heaps_cte h ON i.[object_id] = h.[object_id]
						JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.index_id = 0 
								AND 
									(i.total_reads > 0 OR i.user_updates > 0)
								AND h.[object_id] IS NULL /*don't duplicate the prior check.*/
				OPTION	( RECOMPILE );


			END;
		----------------------------------------
		--Indexaphobia
		--Missing indexes with value >= 5 million: : Check_id 50-59
		----------------------------------------
		BEGIN
			RAISERROR(N'check_id 50: Indexaphobia.', 0,1) WITH NOWAIT;
			WITH	index_size_cte
					  AS ( SELECT	i.[object_id], 
									MAX(i.index_sanity_id) AS index_sanity_id,
								ISNULL (
									CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN 1 ELSE 0 END)
										 AS NVARCHAR(30))+ N' NC indexes exist (' + 
									CASE WHEN SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) > 1024
										THEN CAST(CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END )/1024. 
											AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB); ' 
										ELSE CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) 
											AS NVARCHAR(30)) + N'MB); '
									END + 
										CASE WHEN MAX(sz.[total_rows]) >= 922337203685477 THEN '>= 922,337,203,685,477'
										ELSE REPLACE(CONVERT(NVARCHAR(30),CAST(MAX(sz.[total_rows]) AS money), 1), '.00', '') 
										END +
									+ N' Estimated Rows;' 
								,N'') AS index_size_summary
							FROM	#IndexSanity AS i
							LEFT	JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
						   GROUP BY	i.[object_id])
						   
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   index_usage_summary, index_size_summary, create_tsql, more_info )
						SELECT	50 AS check_id, 
								sz.index_sanity_id,
								N'Indexaphobia' AS findings_group,
								N'High value missing index' AS finding, 
								N'http://BrentOzar.com/go/Indexaphobia' AS URL,
								mi.[statement] + ' estimated benefit: ' + 
									CASE WHEN magic_benefit_number >= 922337203685477 THEN '>= 922,337,203,685,477'
									ELSE REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(magic_benefit_number AS BIGINT) AS money), 1), '.00', '') 
									END AS details,
								missing_index_details AS [definition],
								index_estimated_impact,
								sz.index_size_summary,
								mi.create_tsql,
								mi.more_info
				FROM	#MissingIndexes mi
						LEFT JOIN index_size_cte sz ON mi.[object_id] = sz.object_id
				WHERE magic_benefit_number > 500000
				ORDER BY magic_benefit_number DESC;

	END
		 ----------------------------------------
		--Abnormal Psychology : Check_id 60-79
		----------------------------------------
	BEGIN
			RAISERROR(N'check_id 60: XML indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	60 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'XML Indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							N'' AS index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_XML = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 61: Columnstore indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	61 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							CASE WHEN i.is_NC_columnstore=1
								THEN N'NC Columnstore Index' 
								ELSE N'Clustered Columnstore Index' 
								END AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_NC_columnstore = 1 OR i.is_CX_columnstore=1
					OPTION	( RECOMPILE );


			RAISERROR(N'check_id 62: Spatial indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	62 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Spatial indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_spatial = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 63: Compressed indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	63 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Compressed indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid  + N'. COMPRESSION: ' + sz.data_compression_desc AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE sz.data_compression_desc LIKE '%PAGE%' OR sz.data_compression_desc LIKE '%ROW%' OPTION	( RECOMPILE );

			RAISERROR(N'check_id 64: Partitioned', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	64 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Partitioned indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.partition_key_column_name IS NOT NULL OPTION	( RECOMPILE );

			RAISERROR(N'check_id 65: Non-Aligned Partitioned', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	65 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Non-Aligned index on a partitioned table' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanity AS iParent ON
						i.[object_id]=iParent.[object_id]
						AND iParent.index_id IN (0,1) /* could be a partitioned heap or clustered table */
						AND iParent.partition_key_column_name IS NOT NULL /* parent is partitioned*/         
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.partition_key_column_name IS NULL 
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 66: Recently created tables/indexes (1 week)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	66 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Recently created tables/indexes (1 week)' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid + N' was created on ' + 
								CONVERT(NVARCHAR(16),i.create_date,121) + 
								N'. Tables/indexes which are dropped/created regularly require special methods for index tuning.'
									 AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.create_date >= DATEADD(dd,-7,GETDATE()) 
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 67: Recently modified tables/indexes (2 days)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	67 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Recently modified tables/indexes (2 days)' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid + N' was modified on ' + 
								CONVERT(NVARCHAR(16),i.modify_date,121) + 
								N'. A large amount of recently modified indexes may mean a lot of rebuilds are occurring each night.'
									 AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.modify_date > DATEADD(dd,-2,GETDATE()) 
					and /*Exclude recently created tables unless they've been modified after being created.*/
					(i.create_date < DATEADD(dd,-7,GETDATE()) or i.create_date <> i.modify_date)
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 68: Identity columns within 30 percent of the end of range', 0,1) WITH NOWAIT;
			-- Allowed Ranges: 
				--int -2,147,483,648 to 2,147,483,647
				--smallint -32,768 to 32,768
				--tinyint 0 to 255

				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	68 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Identity column within ' + 									
									CAST (calc1.percent_remaining as nvarchar(256))
									+ N' percent  end of range' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name + N'.' +  QUOTENAME(ic.column_name)
									+ N' is an identity with type ' + ic.system_type_name 
									+ N', last value of ' 
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.last_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', seed of '
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.seed_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', increment of ' + CAST(ic.increment_value AS NVARCHAR(256)) 
									+ N', and range of ' +
										CASE ic.system_type_name WHEN 'int' THEN N'+/- 2,147,483,647'
											WHEN 'smallint' THEN N'+/- 32,768'
											WHEN 'tinyint' THEN N'0 to 255'
										END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexColumns ic on
							i.object_id=ic.object_id
							and i.index_id in (0,1) /* heaps and cx only */
							and ic.is_identity=1
							and ic.system_type_name in ('tinyint', 'smallint', 'int')
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						CROSS APPLY (
							SELECT CAST(CASE WHEN ic.increment_value >= 0
									THEN
										CASE ic.system_type_name 
											WHEN 'int' then (2147483647 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 2147483647.*100
											WHEN 'smallint' then (32768 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 32768.*100
											WHEN 'tinyint' then ( 255 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 255.*100
											ELSE 999
										END
								ELSE --ic.increment_value is negative
										CASE ic.system_type_name 
											WHEN 'int' then ABS(-2147483647 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 2147483647.*100
											WHEN 'smallint' then ABS(-32768 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 32768.*100
											WHEN 'tinyint' then ABS( 0 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 255.*100
											ELSE -1
										END 
								END AS NUMERIC(5,1)) AS percent_remaining
								) as calc1
						WHERE	i.index_id in (1,0)
							and calc1.percent_remaining <= 30
						UNION ALL
						SELECT	68 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Identity column using a negative seed or increment other than 1' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name + N'.' +  QUOTENAME(ic.column_name)
									+ N' is an identity with type ' + ic.system_type_name 
									+ N', last value of ' 
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.last_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', seed of '
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.seed_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', increment of ' + CAST(ic.increment_value AS NVARCHAR(256)) 
									+ N', and range of ' +
										CASE ic.system_type_name WHEN 'int' THEN N'+/- 2,147,483,647'
											WHEN 'smallint' THEN N'+/- 32,768'
											WHEN 'tinyint' THEN N'0 to 255'
										END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexColumns ic on
							i.object_id=ic.object_id
							and i.index_id in (0,1) /* heaps and cx only */
							and ic.is_identity=1
							and ic.system_type_name in ('tinyint', 'smallint', 'int')
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	i.index_id in (1,0)
							and (ic.seed_value < 0 or ic.increment_value <> 1)
						ORDER BY finding, details DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 69: Column collation does not match database collation', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								COUNT(*) as column_count
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
								and collation_name <> @collation
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	69 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Column collation does not match database collation' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST(column_count AS NVARCHAR(20))
									+ N' column' + CASE WHEN column_count > 1 THEN 's' ELSE '' END
									+ N' with a different collation than the db collation of '
									+ @collation	AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 70: Replicated columns', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								COUNT(*) as column_count,
								SUM(CASE is_replicated WHEN 1 THEN 1 ELSE 0 END) as replicated_column_count
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	70 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Replicated columns' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST(replicated_column_count AS NVARCHAR(20))
									+ N' out of ' + CAST(column_count AS NVARCHAR(20))
									+ N' column' + CASE WHEN column_count > 1 THEN 's' ELSE '' END
									+ N' in one or more publications.'
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							and replicated_column_count > 0
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 71: Cascading updates or cascading deletes.', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
								   secret_columns, index_usage_summary, index_size_summary, more_info )
			SELECT	71 AS check_id, 
					null as index_sanity_id,
					N'Abnormal Psychology' AS findings_group,
					N'Cascading Updates or Deletes' AS finding, 
					N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
					N'Foreign Key ' + foreign_key_name +
					N' on ' + QUOTENAME(parent_object_name)  + N'(' + LTRIM(parent_fk_columns) + N')'
						+ N' referencing ' + QUOTENAME(referenced_object_name) + N'(' + LTRIM(referenced_fk_columns) + N')'
						+ N' has settings:'
						+ CASE [delete_referential_action_desc] WHEN N'NO_ACTION' THEN N'' ELSE N' ON DELETE ' +[delete_referential_action_desc] END
						+ CASE [update_referential_action_desc] WHEN N'NO_ACTION' THEN N'' ELSE N' ON UPDATE ' + [update_referential_action_desc] END
							AS details, 
					N'N/A' 
							AS index_definition, 
					N'N/A' AS secret_columns,
					N'N/A' AS index_usage_summary,
					N'N/A' AS index_size_summary,
					(SELECT TOP 1 more_info from #IndexSanity i where i.object_id=fk.parent_object_id)
						AS more_info
			from #ForeignKeys fk
			where [delete_referential_action_desc] <> N'NO_ACTION'
			OR [update_referential_action_desc] <> N'NO_ACTION'

	END

		 ----------------------------------------
		--Workaholics: Check_id 80-89
		----------------------------------------
	BEGIN

		RAISERROR(N'check_id 80: Most scanned indexes (index_usage_stats)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
							   secret_columns, index_usage_summary, index_size_summary )

		--Workaholics according to index_usage_stats
		--This isn't perfect: it mentions the number of scans present in a plan
		--A "scan" isn't necessarily a full scan, but hey, we gotta do the best with what we've got.
		--in the case of things like indexed views, the operator might be in the plan but never executed
		SELECT TOP 5 
			80 AS check_id,
			i.index_sanity_id as index_sanity_id,
			N'Workaholics' as findings_group,
			N'Scan-a-lots (index_usage_stats)' as finding,
			N'http://BrentOzar.com/go/Workaholics' AS URL,
			REPLACE(CONVERT( NVARCHAR(50),CAST(i.user_scans AS MONEY),1),'.00','')
				+ N' scans against ' + i.schema_object_indexid
				+ N'. Latest scan: ' + ISNULL(cast(i.last_user_scan as nvarchar(128)),'?') + N'. ' 
				+ N'ScanFactor=' + cast(((i.user_scans * iss.total_reserved_MB)/1000000.) as NVARCHAR(256)) as details,
			isnull(i.key_column_names_with_sort_order,'N/A') as index_definition,
			isnull(i.secret_columns,'') as secret_columns,
			i.index_usage_summary as index_usage_summary,
			iss.index_size_summary as index_size_summary
		FROM #IndexSanity i
		JOIN #IndexSanitySize iss on i.index_sanity_id=iss.index_sanity_id
		WHERE isnull(i.user_scans,0) > 0
		ORDER BY  i.user_scans * iss.total_reserved_MB DESC;

		RAISERROR(N'check_id 81: Top recent accesses (op stats)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
							   secret_columns, index_usage_summary, index_size_summary )
		--Workaholics according to index_operational_stats
		--This isn't perfect either: range_scan_count contains full scans, partial scans, even seeks in nested loop ops
		--But this can help bubble up some most-accessed tables 
		SELECT TOP 5 
			81 as check_id,
			i.index_sanity_id as index_sanity_id,
			N'Workaholics' as findings_group,
			N'Top recent accesses (index_op_stats)' as finding,
			N'http://BrentOzar.com/go/Workaholics' AS URL,
			ISNULL(REPLACE(
					CONVERT(NVARCHAR(50),cast((iss.total_range_scan_count + iss.total_singleton_lookup_count) AS MONEY),1),
					N'.00',N'') 
				+ N' uses of ' + i.schema_object_indexid + N'. '
				+ REPLACE(CONVERT(NVARCHAR(50), CAST(iss.total_range_scan_count AS MONEY),1),N'.00',N'') + N' scans or seeks. '
				+ REPLACE(CONVERT(NVARCHAR(50), CAST(iss.total_singleton_lookup_count AS MONEY), 1),N'.00',N'') + N' singleton lookups. '
				+ N'OpStatsFactor=' + cast(((((iss.total_range_scan_count + iss.total_singleton_lookup_count) * iss.total_reserved_MB))/1000000.) as varchar(256)),'') as details,
			isnull(i.key_column_names_with_sort_order,'N/A') as index_definition,
			isnull(i.secret_columns,'') as secret_columns,
			i.index_usage_summary as index_usage_summary,
			iss.index_size_summary as index_size_summary
		FROM #IndexSanity i
		JOIN #IndexSanitySize iss on i.index_sanity_id=iss.index_sanity_id
		WHERE isnull(iss.total_range_scan_count,0)  > 0 or isnull(iss.total_singleton_lookup_count,0) > 0
		ORDER BY ((iss.total_range_scan_count + iss.total_singleton_lookup_count) * iss.total_reserved_MB) DESC;


	END

		 ----------------------------------------
		--FINISHING UP
		----------------------------------------
	--BEGIN
		
		 -- choi bo ra  주석 처리
		 /*
			INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,secret_columns,
											   index_usage_summary, index_size_summary )
				VALUES  ( 1000 , N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)	,
						N'' ,   N'http://www.BrentOzar.com/BlitzIndex' ,
						N'Thanks from the Brent Ozar Unlimited(TM), LLC team.',
						N'We hope you found this tool useful.',
						N'If you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
						, N'',N''
						);
		*/

	--END
		RAISERROR(N'Returning results.', 0,1) WITH NOWAIT;
		/*테이블 담기 */
		IF @SERVER_ID < 1000 
		BEGIN

					INSERT INTO DBA.DBO.BLITZ_INDEX
					(REG_DATE, SERVER_ID, DATABASE_NAME, TABLE_NAME, INDEX_NAME, FINDINGS_GROUP, FINDING, DETAILS,INDEX_DEFINITION, 
					 SECRET_COLUMNS, READS, WRITES, USAGE, ROWS, RESERVED, RESERVED_LOB, RESERVED_OVERFLOW, 
					 SIZE, MORE_INFO, TSQL, CHECK_ID 
					 )
					 SELECT GETDATE() AS DATE, 
					 			  @SERVER_ID AS SERVER_ID,
					 			  @DATABASENAME AS DATABASE_NAME, 
					 			  SN.object_name, 
					 			  SN.INDEX_NAME,
					 			  BR.findings_group,
					 			  isnull(br.findings_group,N'') + 
										CASE WHEN ISNULL(br.finding,N'') <> N'' THEN N': ' ELSE N'' END
										+ br.finding AS [Finding], 
									br.details, 
									br.index_definition, 
					 				ISNULL(br.secret_columns,'') AS SECRET_COLUMNS, 
					 				(ISNULL(SN.user_seeks,0) + ISNULL(SN.user_scans,0) + ISNULL(SN.user_lookups,0) ) AS READS, 
					 				ISNULL(SN.USER_UPDATES,0) AS WRITES, 
					 				br.index_usage_summary as usage, 
					 				ISNULL(SI.total_rows,0) AS ROWS, 
					 				ISNULL(SI.total_reserved_MB,0) AS RESERVED, 
					 				ISNULL(SI.total_reserved_LOB_MB,0) AS RESERVED_LOB,
					 				ISNULL(SI.total_reserved_row_overflow_MB ,0) AS RESERVED_OVERFLOW, 
					 				br.index_size_summary AS SIZE, 
					 				COALESCE(br.more_info,sn.more_info,'') AS MORE_INFO, 
					 				COALESCE(br.create_tsql,ts.create_tsql,'') AS TSQL, 
					 				BR.CHECK_ID
					 				
					 FROM #BlitzIndexResults br
						LEFT JOIN #IndexSanity sn ON 
							br.index_sanity_id=sn.index_sanity_id
						LEFT JOIN #IndexSanitySize AS SI ON
							br.index_sanity_id=SI.index_sanity_id
						LEFT JOIN #IndexCreateTsql ts ON 
							br.index_sanity_id=ts.index_sanity_id
					ORDER BY [check_id] ASC, blitz_result_id ASC, findings_group;
					 
		END
		ELSE IF @SERVER_ID > 1000
		BEGIN
				INSERT INTO DBADMIN.DBO.BLITZ_INDEX
					(REG_DATE, SERVER_ID, DATABASE_NAME, TABLE_NAME, INDEX_NAME, FINDINGS_GROUP, FINDING, DETAILS,INDEX_DEFINITION, 
					 SECRET_COLUMNS, READS, WRITES, USAGE, ROWS, RESERVED, RESERVED_LOB, RESERVED_OVERFLOW, 
					 SIZE, MORE_INFO, TSQL, CHECK_ID
					 )
					 SELECT GETDATE() AS DATE, 
					 			  @SERVER_ID AS SERVER_ID,
					 			  @DATABASENAME AS DATABASE_NAME, 
					 			  SN.object_name, 
					 			  SN.INDEX_NAME,
					 			  BR.findings_group,
					 			  isnull(br.findings_group,N'') + 
										CASE WHEN ISNULL(br.finding,N'') <> N'' THEN N': ' ELSE N'' END
										+ br.finding AS [Finding], 
									br.details, 
									br.index_definition, 
					 				ISNULL(br.secret_columns,'') AS SECRET_COLUMNS, 
					 				(ISNULL(SN.user_seeks,0) + ISNULL(SN.user_scans,0) + ISNULL(SN.user_lookups,0) ) AS READS, 
					 				ISNULL(SN.USER_UPDATES,0) AS WRITES, 
					 				br.index_usage_summary, 
					 				ISNULL(SI.total_rows,0) AS ROWS, 
					 				ISNULL(SI.total_reserved_MB,0) AS RESERVED, 
					 				ISNULL(SI.total_reserved_LOB_MB,0) AS RESERVED_LOB,
					 				ISNULL(SI.total_reserved_row_overflow_MB ,0) AS RESERVED_OVERFLOW, 
					 				br.index_size_summary AS SIZE, 
					 				COALESCE(br.more_info,sn.more_info,'') AS MORE_INFO, 
					 				COALESCE(br.create_tsql,ts.create_tsql,'') AS TSQL, 
					 				BR.CHECK_ID
					 				
					 FROM #BlitzIndexResults br
						LEFT JOIN #IndexSanity sn ON 
							br.index_sanity_id=sn.index_sanity_id
						LEFT JOIN #IndexSanitySize AS SI ON
							br.index_sanity_id=SI.index_sanity_id
						LEFT JOIN #IndexCreateTsql ts ON 
							br.index_sanity_id=ts.index_sanity_id
					ORDER BY [check_id] ASC, blitz_result_id ASC, findings_group;
		END
	
	
			
			
			
		/*Return results.*/
		--SELECT isnull(br.findings_group,N'') + 
		--		CASE WHEN ISNULL(br.finding,N'') <> N'' THEN N': ' ELSE N'' END
		--		+ br.finding AS [Finding], 
		--	br.URL, 
		--	br.details AS [Details: schema.table.index(indexid)], 
		--	br.index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}], 
		--	ISNULL(br.secret_columns,'') AS [Secret Columns],          
		--	br.index_usage_summary AS [Usage], 
		--	br.index_size_summary AS [Size],
		--	COALESCE(br.more_info,sn.more_info,'') AS [More Info],
		--	COALESCE(br.create_tsql,ts.create_tsql,'') AS [Create TSQL]
		--FROM #BlitzIndexResults br
		--LEFT JOIN #IndexSanity sn ON 
		--	br.index_sanity_id=sn.index_sanity_id
		--LEFT JOIN #IndexCreateTsql ts ON 
		--	br.index_sanity_id=ts.index_sanity_id
		--ORDER BY [check_id] ASC, blitz_result_id ASC, findings_group;

	END; /* End @Mode=0 (diagnose)*/
	ELSE IF @Mode=1 /*Summarize*/
	BEGIN
	--This mode is to give some overall stats on the database.
		RAISERROR(N'@Mode=1, we are summarizing.', 0,1) WITH NOWAIT;

		IF @SERVER_ID < 1000 
		BEGIN
			INSERT INTO DBA.DBO.BLITZ_INDEX_SUMMARY
			SELECT  
				GETDATE() AS DATE, 
				@SERVER_ID AS SERVER_ID, 
				@DATABASENAME AS DATABASE_NAME,
				CAST((COUNT(*)) AS NVARCHAR(256)) AS [Number Objects],
				CAST(CAST(SUM(sz.total_reserved_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [All GB],
				CAST(CAST(SUM(sz.total_reserved_LOB_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [LOB GB],
				CAST(CAST(SUM(sz.total_reserved_row_overflow_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [Row Overflow GB],
				CAST(SUM(CASE WHEN index_id=1 THEN 1 ELSE 0 END)AS NVARCHAR(50)) AS [Clustered Tables],
				CAST(SUM(CASE WHEN index_id=1 THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Clustered Tables GB],
				SUM(CASE WHEN index_id NOT IN (0,1) THEN 1 ELSE 0 END) AS [NC Indexes],
				CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [NC Indexes GB],
				CASE WHEN SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)  > 0 THEN
					CAST(SUM(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
						/ SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) AS NUMERIC(29,1)) 
					ELSE 0 END AS [ratio table: NC Indexes],
				SUM(CASE WHEN index_id=0 THEN 1 ELSE 0 END) AS [Heaps],
				CAST(SUM(CASE WHEN index_id=0 THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Heaps GB],
				SUM(CASE WHEN index_id IN (0,1) AND partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned Tables],
				SUM(CASE WHEN index_id NOT IN (0,1) AND  partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned NCs],
				CAST(SUM(CASE WHEN partition_key_column_name IS NOT NULL THEN sz.total_reserved_MB ELSE 0 END)/1024. AS numeric(29,1)) AS [Partitioned GB],
				SUM(CASE WHEN filter_definition <> '' THEN 1 ELSE 0 END) AS [Filtered Indexes],
				SUM(CASE WHEN is_indexed_view=1 THEN 1 ELSE 0 END) AS [Indexed Views],
				MAX(total_rows) AS [Max Row Count],
				CAST(MAX(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Max Table GB],
				CAST(MAX(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Max NC Index GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count Tables > 1GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count Tables > 10GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count Tables > 100GB],	
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count NCs > 1GB],
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count NCs > 10GB],
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count NCs > 100GB],
				MIN(create_date) AS [Oldest Create Date],
				MAX(create_date) AS [Most Recent Create Date],
				MAX(modify_date) as [Most Recent Modify Date],
				1 as [Display Order] 
			FROM #IndexSanity AS i
			--left join here so we don't lose disabled nc indexes
			LEFT JOIN #IndexSanitySize AS sz 
				ON i.index_sanity_id=sz.index_sanity_id 
			--UNION ALL
			--SELECT	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)	,		
			--		N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
			--		N'From Brent Ozar Unlimited(TM)' ,   
			--		N'http://BrentOzar.com/BlitzIndex' ,
			--		N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
			--		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			--		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			--		NULL,0 as display_order
			ORDER BY [Display Order] ASC
			OPTION (RECOMPILE);
		END
		ELSE IF @SERVER_ID > 1000
		BEGIN
				INSERT INTO DBADMIN.DBO.BLITZ_INDEX_SUMMARY
			SELECT  
				GETDATE() AS DATE, 
				@SERVER_ID AS SERVER_ID, 
				@DATABASENAME AS DATABASE_NAME,
				CAST((COUNT(*)) AS NVARCHAR(256)) AS [Number Objects],
				CAST(CAST(SUM(sz.total_reserved_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [All GB],
				CAST(CAST(SUM(sz.total_reserved_LOB_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [LOB GB],
				CAST(CAST(SUM(sz.total_reserved_row_overflow_MB)/
					1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [Row Overflow GB],
				CAST(SUM(CASE WHEN index_id=1 THEN 1 ELSE 0 END)AS NVARCHAR(50)) AS [Clustered Tables],
				CAST(SUM(CASE WHEN index_id=1 THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Clustered Tables GB],
				SUM(CASE WHEN index_id NOT IN (0,1) THEN 1 ELSE 0 END) AS [NC Indexes],
				CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [NC Indexes GB],
				CASE WHEN SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)  > 0 THEN
					CAST(SUM(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
						/ SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) AS NUMERIC(29,1)) 
					ELSE 0 END AS [ratio table: NC Indexes],
				SUM(CASE WHEN index_id=0 THEN 1 ELSE 0 END) AS [Heaps],
				CAST(SUM(CASE WHEN index_id=0 THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Heaps GB],
				SUM(CASE WHEN index_id IN (0,1) AND partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned Tables],
				SUM(CASE WHEN index_id NOT IN (0,1) AND  partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned NCs],
				CAST(SUM(CASE WHEN partition_key_column_name IS NOT NULL THEN sz.total_reserved_MB ELSE 0 END)/1024. AS numeric(29,1)) AS [Partitioned GB],
				SUM(CASE WHEN filter_definition <> '' THEN 1 ELSE 0 END) AS [Filtered Indexes],
				SUM(CASE WHEN is_indexed_view=1 THEN 1 ELSE 0 END) AS [Indexed Views],
				MAX(total_rows) AS [Max Row Count],
				CAST(MAX(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Max Table GB],
				CAST(MAX(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/1024. AS numeric(29,1)) AS [Max NC Index GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count Tables > 1GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count Tables > 10GB],
				SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count Tables > 100GB],	
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count NCs > 1GB],
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count NCs > 10GB],
				SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count NCs > 100GB],
				MIN(create_date) AS [Oldest Create Date],
				MAX(create_date) AS [Most Recent Create Date],
				MAX(modify_date) as [Most Recent Modify Date],
				1 as [Display Order] 
			FROM #IndexSanity AS i
			--left join here so we don't lose disabled nc indexes
			LEFT JOIN #IndexSanitySize AS sz 
				ON i.index_sanity_id=sz.index_sanity_id 
			--UNION ALL
			--SELECT	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)	,		
			--		N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
			--		N'From Brent Ozar Unlimited(TM)' ,   
			--		N'http://BrentOzar.com/BlitzIndex' ,
			--		N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
			--		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			--		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			--		NULL,0 as display_order
			ORDER BY [Display Order] ASC
			OPTION (RECOMPILE);
		END
	   	
	END /* End @Mode=1 (summarize)*/
	ELSE IF @Mode=2 /*Index Detail*/
	BEGIN
		--This mode just spits out all the detail without filters.
		--This supports slicing AND dicing in Excel
		RAISERROR(N'@Mode=2, here''s the details on existing indexes.', 0,1) WITH NOWAIT;

		SELECT	database_name AS [Database Name], 
				[schema_name] AS [Schema Name], 
				[object_name] AS [Object Name], 
				ISNULL(index_name, '') AS [Index Name], 
				cast(index_id as VARCHAR(10))AS [Index ID],
				schema_object_indexid AS [Details: schema.table.index(indexid)], 
				CASE	WHEN index_id IN ( 1, 0 ) THEN 'TABLE'
					ELSE 'NonClustered'
					END AS [Object Type], 
				index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}],
				ISNULL(LTRIM(key_column_names_with_sort_order), '') AS [Key Column Names With Sort],
				ISNULL(count_key_columns, 0) AS [Count Key Columns],
				ISNULL(include_column_names, '') AS [Include Column Names], 
				ISNULL(count_included_columns,0) AS [Count Included Columns],
				ISNULL(secret_columns,'') AS [Secret Column Names], 
				ISNULL(count_secret_columns,0) AS [Count Secret Columns],
				ISNULL(partition_key_column_name, '') AS [Partition Key Column Name],
				ISNULL(filter_definition, '') AS [Filter Definition], 
				is_indexed_view AS [Is Indexed View], 
				is_primary_key AS [Is Primary Key],
				is_XML AS [Is XML],
				is_spatial AS [Is Spatial],
				is_NC_columnstore AS [Is NC Columnstore],
				is_CX_columnstore AS [Is CX Columnstore],
				is_disabled AS [Is Disabled], 
				is_hypothetical AS [Is Hypothetical],
				is_padded AS [Is Padded], 
				fill_factor AS [Fill Factor], 
				is_referenced_by_foreign_key AS [Is Reference by Foreign Key], 
				last_user_seek AS [Last User Seek], 
				last_user_scan AS [Last User Scan], 
				last_user_lookup AS [Last User Lookup],
				last_user_update AS [Last User Update], 
				total_reads AS [Total Reads], 
				user_updates AS [User Updates], 
				reads_per_write AS [Reads Per Write], 
				index_usage_summary AS [Index Usage], 
				sz.partition_count AS [Partition Count],
				sz.total_rows AS [Rows], 
				sz.total_reserved_MB AS [Reserved MB], 
				sz.total_reserved_LOB_MB AS [Reserved LOB MB], 
				sz.total_reserved_row_overflow_MB AS [Reserved Row Overflow MB],
				sz.index_size_summary AS [Index Size], 
				sz.total_row_lock_count AS [Row Lock Count],
				sz.total_row_lock_wait_count AS [Row Lock Wait Count],
				sz.total_row_lock_wait_in_ms AS [Row Lock Wait ms],
				sz.avg_row_lock_wait_in_ms AS [Avg Row Lock Wait ms],
				sz.total_page_lock_count AS [Page Lock Count],
				sz.total_page_lock_wait_count AS [Page Lock Wait Count],
				sz.total_page_lock_wait_in_ms AS [Page Lock Wait ms],
				sz.avg_page_lock_wait_in_ms AS [Avg Page Lock Wait ms],
				sz.total_index_lock_promotion_attempt_count AS [Lock Escalation Attempts],
				sz.total_index_lock_promotion_count AS [Lock Escalations],
				sz.data_compression_desc AS [Data Compression],
				i.create_date AS [Create Date],
				i.modify_date as [Modify Date],
				more_info AS [More Info],
				1 as [Display Order]
		FROM	#IndexSanity AS i --left join here so we don't lose disabled nc indexes
				LEFT JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
		UNION ALL
		SELECT 	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)			
				N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
				N'From Brent Ozar Unlimited(TM)' ,   
				N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL, NULL,NULL, NULL, NULL, NULL, NULL,NULL,NULL,
				0 as [Display Order]
		ORDER BY [Display Order] ASC, [Reserved MB] DESC
		OPTION (RECOMPILE);

	END /* End @Mode=2 (index detail)*/
	ELSE IF @Mode=3 /*Missing index Detail*/
	BEGIN

		IF @SERVER_ID < 1000 
		BEGIN
			INSERT INTO DBA.DBO.BLITZ_MISSING_INDEX
			SELECT 
				GETDATE() AS REG_DATE, 
				@SERVER_ID AS SERVER_ID, 
				database_name AS [Database], 
				[schema_name] AS [Schema], 
				table_name AS [Table], 
				CAST(magic_benefit_number AS BIGINT)
					AS [Magic Benefit Number], 
				missing_index_details AS [Missing Index Details], 
				avg_total_user_cost AS [Avg Query Cost], 
				avg_user_impact AS [Est Index Improvement], 
				user_seeks AS [Seeks], 
				user_scans AS [Scans],
				unique_compiles AS [Compiles], 
				equality_columns AS [Equality Columns], 
				inequality_columns AS [Inequality Columns], 
				included_columns AS [Included Columns], 
				index_estimated_impact AS [Estimated Impact], 
				create_tsql AS [Create TSQL], 
				more_info AS [More Info],
				1 as [Display Order]

			FROM #MissingIndexes
		--UNION ALL
		--SELECT 				
		--	N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
		--	N'From Brent Ozar Unlimited(TM)' ,   
		--	N'http://BrentOzar.com/BlitzIndex' ,
		--	100000000000,
		--	N'Thanks from the Brent Ozar Unlimited(TM) team. We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
		--	NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		--	NULL, 0 as display_order
		ORDER BY [Display Order] ASC, [Magic Benefit Number] DESC
		END
		ELSE IF @SERVER_ID > 1000
		BEGIN
			INSERT INTO DBADMIN.DBO.BLITZ_MISSING_INDEX
			SELECT 
				GETDATE() AS REG_DATE, 
				@SERVER_ID AS SERVER_ID, 
				database_name AS [Database], 
				[schema_name] AS [Schema], 
				table_name AS [Table], 
				CAST(magic_benefit_number AS BIGINT)
					AS [Magic Benefit Number], 
				missing_index_details AS [Missing Index Details], 
				avg_total_user_cost AS [Avg Query Cost], 
				avg_user_impact AS [Est Index Improvement], 
				user_seeks AS [Seeks], 
				user_scans AS [Scans],
				unique_compiles AS [Compiles], 
				equality_columns AS [Equality Columns], 
				inequality_columns AS [Inequality Columns], 
				included_columns AS [Included Columns], 
				index_estimated_impact AS [Estimated Impact], 
				create_tsql AS [Create TSQL], 
				more_info AS [More Info],
				1 as [Display Order]
			FROM #MissingIndexes
		END

	END /* End @Mode=3 (index detail)*/
END
END TRY
BEGIN CATCH
		RAISERROR (N'Failure analyzing temp tables.', 0,1) WITH NOWAIT;

		SELECT	@msg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		RAISERROR (@msg, 
               @ErrorSeverity, 
               @ErrorState 
               );
		
		WHILE @@trancount > 0 
			ROLLBACK;

		RETURN;
	END CATCH;
go

/* =============================================================================
프로그램ID : dbo.SP_DBA_CHAGNE_LOGIN_DELETE_MAIN
업  무  명	: DB LOGIN 삭제
비      고 :
drop proc SP_DBA_CHAGNE_LOGIN_DELETE_MAIN
EXEC	dbo.SP_DBA_CHAGNE_LOGIN_DELETE_MAIN 'ebaykorea\heyang'
===============================================================================
수정일		수정자				수정내용
-------------------------------------------------------------------------------
20140717	안지은		SQL 계정 > Window 계정으로 변경됨에 따라 기존 조건(sl_ 예외처리) 삭제
						DB 버전에 따라 다른 명령어 적용 (SQL2005 서버-ERPDB/NAUTOMAILDB/MISDB1/TICKETDB1/TRACELOGDB1/EPDB2에서는 EXEC(@SQL)로 실행)
============================================================================= */
CREATE PROC [dbo].[SP_DBA_CHAGNE_LOGIN_DELETE_MAIN]
@sql_login VARCHAR(50)
--, @ERR_MSG VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
           DECLARE @I INT, @MAX_CNT INT, @SQL NVARCHAR(MAX), @DB_NAME VARCHAR(200), @TEST VARCHAR(MAX), @ERR_MSG VARCHAR(1000)

           BEGIN TRY
				SET @I = 1 
           
				CREATE TABLE #DB_TEMP (SEQNO INT IDENTITY(1,1), DB_NAME VARCHAR(200))
    
				INSERT INTO #DB_TEMP (DB_NAME)
				SELECT name FROM sys.DATABASES (NOLOCK) WHERE database_id > 4 AND is_read_only = 0 AND state = 0 ORDER BY database_id
        
				SELECT @MAX_CNT = MAX(SEQNO) FROM #DB_TEMP
    
				WHILE (@I <= @MAX_CNT)
				BEGIN
						SELECT @DB_NAME = DB_NAME FROM #DB_TEMP
						WHERE SEQNO = @I
            			
						SET @SQL = 'SELECT * INTO ##TMP_LOGIN_ID FROM '+@DB_NAME+'.SYS.SYSUSERS (NOLOCK) WHERE NAME = '''+@sql_login+''''
						EXEC (@SQL)
						IF EXISTS (SELECT * FROM ##TMP_LOGIN_ID (NOLOCK))
						BEGIN 
							SET @SQL = @DB_NAME +'..SP_DBA_CHANGE_LOGIN_DELETE_SUB @sql_login1'
							EXEC SP_EXECUTESQL @SQL
							,    N'@sql_login1 VARCHAR(50)'
							,    @sql_login1 = @sql_login				-- SQL2005버전이 아니면 SP_EXECUTESQL로 실행
						END

						SET @I = @I + 1
						DROP TABLE ##TMP_LOGIN_ID
				END
           
				SET @TEST = 'DROP LOGIN ' + QUOTENAME(@sql_login)
				EXEC (@TEST)
           END TRY
           BEGIN CATCH
        DECLARE @ERROR_MSG VARCHAR(4000) 
        SET @ERROR_MSG = ERROR_MESSAGE()
        SET @ERR_MSG = @ERROR_MSG
    END CATCH

    SELECT @ERR_MSG AS ERR_MSG
END
go

/* =============================================================================
프로그램ID : dbo.SP_DBA_CHAGNE_LOGIN_DELETE_MAIN
업  무  명	: DB LOGIN 삭제
비      고 :
drop proc SP_DBA_CHAGNE_LOGIN_DELETE_MAIN_SYNC_SERVER
EXEC	dbo.SP_DBA_CHAGNE_LOGIN_DELETE_MAIN_SYNC_SERVER 'ebaykorea\jian'
===============================================================================
수정일		수정자				수정내용
-------------------------------------------------------------------------------
20150210	안지은		권한 만료 처리된 계정을 삭제처리 하는 SP로 원본 서버일 경우 Login만 삭제
						DB 버전에 따라 다른 명령어 적용 (SQL2005 서버-ERPDB/NAUTOMAILDB/MISDB1/TICKETDB1/TRACELOGDB1/EPDB2에서는 EXEC(@SQL)로 실행)
============================================================================= */
CREATE PROC [dbo].[SP_DBA_CHAGNE_LOGIN_DELETE_MAIN_SYNC_SERVER]
@sql_login VARCHAR(50)
--, @ERR_MSG VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @I INT, @MAX_CNT INT, @SQL NVARCHAR(MAX), @DB_NAME VARCHAR(200), @TEST VARCHAR(MAX), @ERR_MSG VARCHAR(1000)

	BEGIN TRY                       
		SET @TEST = 'DROP LOGIN ' + QUOTENAME(@sql_login)
		EXEC (@TEST)
	END TRY
	BEGIN CATCH
		DECLARE @ERROR_MSG VARCHAR(4000) 
		SET @ERROR_MSG = ERROR_MESSAGE()
		SET @ERR_MSG = @ERROR_MSG
	END CATCH

    SELECT @ERR_MSG AS ERR_MSG
END
go





/* =============================================================================
프로그램ID : dbo.SP_DBA_CHANGE_LOGIN_DELETE_SUB]
업  무  명	: DB USER 삭제
비      고 :
drop proc SP_DBA_CHANGE_LOGIN_DELETE_SUB]
EXEC	dbo.SP_DBA_CHANGE_LOGIN_DELETE_SUB] 'ebaykorea\jian'
===============================================================================
수정일		수정자				수정내용
-------------------------------------------------------------------------------
20140717	안지은		SQL 계정 > Window 계정으로 변경됨에 따라 기존 조건(sl_ 예외처리) 삭제
						DB 버전에 따라 다른 명령어 적용 (SQL2005 서버-ERPDB/NAUTOMAILDB/MISDB1/TICKETDB1/TRACELOGDB1/EPDB2에서는 EXEC(@SQL)로 실행)
============================================================================= */
CREATE PROC [dbo].[SP_DBA_CHANGE_LOGIN_DELETE_SUB]
@sql_login VARCHAR(50)

AS
BEGIN
    SET NOCOUNT ON 

    BEGIN TRY 
        DECLARE @I INT, @MAX_CNT INT, @SQL VARCHAR(MAX), @DB_NAME VARCHAR(100), @TEST VARCHAR(MAX), @ROWCOUNT INT
        DECLARE @USER VARCHAR(100), @ERR_MSG VARCHAR(MAX)
        
        SET @SQL = ''

        SELECT @USER = B.NAME 
        FROM sys.syslogins A (NOLOCK)
        LEFT JOIN sys.sysusers B (NOLOCK) ON A.SID = B.SID
        WHERE A.NAME = @sql_login

        SET @SQL = 'USE '+ DB_NAME()
        SET @SQL = @SQL + CHAR(10) + 'DROP USER ' + QUOTENAME(@USER)

        EXEC (@SQL)
        PRINT @SQL
    END TRY 

    BEGIN CATCH
        DECLARE @ERROR_MSG VARCHAR(4000) 
        SET @ERROR_MSG = ERROR_MESSAGE()
        SET @ERR_MSG = @ERROR_MSG
    END CATCH

    SELECT @ERR_MSG AS ERR_MSG
END
go

/*************************************************************************  
* 프로시저명: dbo.SP_DBA_CHECK_DATA_COMPARE
* 작성정보	: 2013-03-26 BY CHOI BO RA
* 관련페이지:  
* 내용		: 테이블 이관 후 조건 비교  
* 수정정보	: 
			2013-06-28 서은미 unique index 또한 PK처럼 이름 변경되도록 수정
			2013-07-04 김대경 권한체크 오류수정 ERROR_NUMBER=15330(권한이 없는 경우)
			2013-07-09 최보라 rollback rename, 변수 초기화 추가
			2013-07-10 노상국 INDEX 없는경우 오류 수정(index_id=0, HEAP)
			2013-07-10 서은미 INDEX 이름에 _OLD가 있는 경우 오류 수정(replace구문에 old제거, line 133)
			2013-07-12 최보라 스키마 바인딩 VIEW CHECK 추가
			2013-07-25 서은미 권한 체크 try~catch source,target쪽 각각 체크하도록 오류수정
**************************************************************************/
CREATE PROCEDURE [dbo].[SP_DBA_CHECK_DATA_COMPARE]
	@SOURCE_DB_NAME			SYSNAME,
	@SOURCE_DB_SCHEMA		SYSNAME,
	@SOURCE_TABLE_NAME		SYSNAME,
	@TARGET_DB_NAME			SYSNAME  = NULL, 
	@TARGET_TABLE_NAME		SYSNAME  = NULL, 
	@SAMPLE					INT = 5

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @DB_NAME  SYSNAME
DECLARE @STR_SQL  NVARCHAR(4000), @STR_PARM NVARCHAR(500)
DECLARE @SOURCE_FULL_OBJECT SYSNAME, @TARGET_FULL_OBJECT SYSNAME
DECLARE @SOURCE_COUNT BIGINT, @TARGET_COUNT BIGINT

/* BODY */

IF @TARGET_DB_NAME IS NULL SET @TARGET_DB_NAME = @SOURCE_DB_NAME
IF @TARGET_TABLE_NAME IS NULL SET @TARGET_TABLE_NAME = @SOURCE_TABLE_NAME + '_ETAM'

SET @SOURCE_FULL_OBJECT = @SOURCE_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @SOURCE_TABLE_NAME
SET @TARGET_FULL_OBJECT = @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @TARGET_TABLE_NAME



-- 1. 데이터 건수 비교 
PRINT '/*** DATABASE : ' + @TARGET_DB_NAME + ' Table Name : ' + @TARGET_TABLE_NAME + ' Check Data Start ****/' 
PRINT  ''

SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0

SET @STR_SQL = 'SELECT	@SOURCE_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END	) ' + CHAR(10)
			  +'FROM ' + @SOURCE_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL ='SELECT @TARGET_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END	)  ' + CHAR(10)
			+ 'FROM ' + @TARGET_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @TARGET_FULL_OBJECT +''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	--PRINT '--1.건수 비교 : Fault 필수 확인 '
	RAISERROR ( '--1.건수 비교 : Fault 필수 확인',  16,1)     

	SELECT '1.건수 비교 ' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
END
ELSE 
	PRINT '--1.건수 비교 : OK '



-- 2.인덱스 건수 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL ='SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT



SET @STR_SQL ='SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--2.인덱스 건수 비교  : Fault 필수 확인',  16,1)     
	SELECT '2.인덱스 건수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

	SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
	EXECUTE sp_executesql  @STR_SQL

	
	SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
	EXECUTE sp_executesql  @STR_SQL

END	
ELSE 
	PRINT '--2.인덱스 건수 비교 : OK'


-- 2-1. 인덱스 이름 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #SOURCE_INDEX_NAME 
( SOUCE_TABLE_NAME SYSNAME, SOURCE_NAME SYSNAME , SOURCE_TYPE  NVARCHAR(60), SOURCE_PRIMARY_KEY BIT, SOURCE_UNIQUE BIT )

CREATE TABLE #TARGET_INDEX_NAME 
( SEQNO INT IDENTITY(1,1)  NOT NULL, 
 TARGET_TABLE_NAME SYSNAME, TARGET_NAME SYSNAME , TARGET_TYPE NVARCHAR(60), TARGET_PRIMARY_KEY BIT, TARGET_UNIQUE BIT )


SET @STR_SQL ='INSERT INTO #SOURCE_INDEX_NAME' + CHAR(10)
			 +'SELECT ''' + @SOURCE_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
			 + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'

EXECUTE sp_executesql  @STR_SQL


SET @STR_SQL ='INSERT INTO #TARGET_INDEX_NAME' + CHAR(10)
			 +'SELECT ''' + @TARGET_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
			 + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
EXECUTE sp_executesql  @STR_SQL


SELECT @SOURCE_COUNT = COUNT(*)
FROM #SOURCE_INDEX_NAME AS A 
	--LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
	LEFT JOIN #TARGET_INDEX_NAME AS B ON A.SOURCE_NAME = REPLACE(B.TARGET_NAME, '_ETAM', '')
WHERE B.TARGET_NAME IS NULL



IF @SOURCE_COUNT > 0
BEGIN
	RAISERROR ( '--2-1.Index 이름 Check : Fault 필수 확인 ',  16,1)  
	
	SELECT A.*, B.*
	FROM #SOURCE_INDEX_NAME AS A 
		LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
	WHERE B.TARGET_NAME IS NULL

END
ELSE 
	PRINT '--2-1.Index 이름 Check : OK'



-- 3. CHECK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'
 
EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--3.CHECK 비교  : Fault 필수 확인 ',  16,1)  
	SELECT '3.CHECK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

	SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL
	
	SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
				 + @TARGET_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('+ @TARGET_FULL_OBJECT+ ')'
	EXECUTE sp_executesql  @STR_SQL
	

END
ELSE 
	PRINT '--3.CHECK 비교 : OK'

-- 4.DEFAULT 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT



SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--4.DEFAULT 비교  : Fault 필수 확인 ',  16,1)  
	SELECT '4.DEFAULT 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
	
	SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL
	
	SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
				 + @TARGET_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--4.DEFAULT 비교 : OK'



-- 5.FK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--5.FK 비교  : Fault 필수 확인 ',  16,1)  
	SELECT '5.FK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
	
	SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL
	
	SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
				 + @TARGET_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--5.FK 비교 : OK'

-- 6.TRIGGERS 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.triggers WHERE PARENT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
	
	RAISERROR ( '--6.Trigger 존재: 트리거명 확인',  16,1)  

	SET @STR_SQL ='SELECT ''6.Trigger 존재, DROP/CREATE 처리'' AS STEP, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.triggers WHERE PARENT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--6.Trigger 존재 하지 않음 : OK'
 



-- 7.권한 CHECK
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #HELPROTECT 
( SEQNO INT IDENTITY(1,1), OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

CREATE TABLE #HELPROTECT_TARGET 
(  OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

BEGIN TRY
	SET @SOURCE_COUNT = 0
	SET @STR_SQL= 'USE ' + @SOURCE_DB_NAME + CHAR(10)
			+ 'EXEC SP_HELPROTECT ' + @SOURCE_TABLE_NAME  

	INSERT INTO #HELPROTECT
	EXEC(@STR_SQL)

	SET @SOURCE_COUNT =@@ROWCOUNT 

END TRY 
BEGIN CATCH
	IF ERROR_NUMBER() = 15330 SET @SOURCE_COUNT = 0
END CATCH

BEGIN TRY
	SET @TARGET_COUNT = 0

	SET @STR_SQL= 'USE ' + @TARGET_DB_NAME + CHAR(10)
			+ 'EXEC SP_HELPROTECT ' + @TARGET_TABLE_NAME 

	INSERT INTO #HELPROTECT_TARGET
	EXEC(@STR_SQL)
	SET @TARGET_COUNT =@@ROWCOUNT
END TRY 
BEGIN CATCH
	IF ERROR_NUMBER() = 15330 SET @TARGET_COUNT = 0	
END CATCH

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--7.권한 CHECK : Fault , 권한 생성 ',  16,1)  
	SELECT '7.권한 CHECK' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
	PRINT ''
	
	DECLARE @I  INT
	SET @I =1
	SET @STR_SQL = ''
	WHILE ( @I <= @SOURCE_COUNT)
	BEGIN
		
		SELECT @STR_SQL = @STR_SQL+ 'USE ' + @TARGET_DB_NAME + CHAR(10) 
					  + 'GRANT ' + [ACTION] + ' ON OBJECT::' + @TARGET_TABLE_NAME + ' TO ' + GRANTEE + CHAR(10)
		FROM #HELPROTECT WHERE SEQNO = @I

		SET @I = @I + 1
	END

	PRINT @STR_SQL
	


END
ELSE 
	PRINT '--7.권한 CHECK : OK'

-- 8.컬럼수 비교
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT 



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--8.컬럼수 비교  : Fault 필수 확인 ',  16,1)  

	SELECT '8.컬럼수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

	SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL
	
	SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
				 + @TARGET_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--8.컬럼수 비교 : OK'



-- 9.VIEW 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'
EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
	
	RAISERROR ( '--9.VIEW 존재 : VIEW 명 확인',  16,1)  
	SET @STR_SQL ='SELECT ''9.VIEW 존재,ALTER 처리'' AS STEP, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'


	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--9.VIEW 존재 하지 않음 : OK'

-- 9-1 스미마 바인딩 된 VIEW
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies ' + CHAR(10)
			+ 'WHERE referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND CLASS > 0 AND IS_SELECTED = 1 ' + CHAR(10)
			+ ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> OBJECT_ID '
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

IF @SOURCE_COUNT >0 
BEGIN 
	
	  
	SET @STR_SQL ='SELECT DISTINCT ''9.스미카 바인딩 VIEW 존재,ALTER 처리'' AS STEP, NAME' + CHAR(10)
				 + 'FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies AS D JOIN ' + @SOURCE_DB_NAME + '.SYS.OBJECTS AS O ON D.OBJECT_ID = O.OBJECT_ID ' + CHAR(10)
				 + 'WHERE D.referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND D.CLASS > 0 AND D.IS_SELECTED = 1 ' + CHAR(10)
				 + ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> D.OBJECT_ID '
	EXECUTE sp_executesql  @STR_SQL

	RAISERROR ( '--9-1.스미카 바인딩 VIEW 존재 : VIEW 명 확인',  16,1)

END
ELSE 
	PRINT '--9-1. 스미카 바인딩 VIEW 존재 하지 않음 : OK'


 
--10.통계 확인 '
PRINT ''
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
	
	RAISERROR ( '--10.통계 확인  : Fault 필수 확인 ',  16,1)  

	SELECT '10.통계 확인' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

	SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
				 + @SOURCE_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
				 + ' and user_created =1'

	EXECUTE sp_executesql  @STR_SQL
	
	SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
				 + @TARGET_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
				 + ' and user_created =1'

	EXECUTE sp_executesql  @STR_SQL

END
ELSE 
	PRINT '--10.통계 확인 : OK'




PRINT '/****11.DATA CHECK : 쿼리 실행, 틀린 DATA 결과 나옴  *************************/'
PRINT ''

EXEC DBO.SP_DBA_CHECK_DATA_COMPARE_SCRIPT @SOURCE_DB_NAME, @SOURCE_DB_SCHEMA, 
	 @SOURCE_TABLE_NAME, @TARGET_DB_NAME, @TARGET_TABLE_NAME, @SAMPLE


-- 12. 최종 확인 SP_RENAME 스크립트.
PRINT '/**** SP_RENAME  *************************/'
PRINT 'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + ''',''' + @SOURCE_TABLE_NAME + '_OLD'''
PRINT 'EXEC SP_RENAME ''' + @TARGET_TABLE_NAME + ''',''' + REPLACE(@TARGET_TABLE_NAME, '_ETAM', '') + ''''

DECLARE @SORUCE_PK_INDEX_NAME SYSNAME, @TARGET_INDEX_COUNT INT
DECLARE @SORUCE_UNIQUE_INDEX_NAME SYSNAME 

SET @SORUCE_PK_INDEX_NAME= ''
SELECT  @SORUCE_PK_INDEX_NAME = SOURCE_NAME
FROM #SOURCE_INDEX_NAME WHERE SOURCE_PRIMARY_KEY = 1

SET @SORUCE_UNIQUE_INDEX_NAME= ''
SELECT  @SORUCE_UNIQUE_INDEX_NAME = SOURCE_NAME
FROM #SOURCE_INDEX_NAME WHERE SOURCE_UNIQUE = 1

--SELECT @SORUCE_PK_INDEX_NAME,@SORUCE_UNIQUE_INDEX_NAME

PRINT ''

IF @SORUCE_PK_INDEX_NAME != ''
	PRINT 'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + '_OLD.' + @SORUCE_PK_INDEX_NAME + ''', ''' + @SORUCE_PK_INDEX_NAME + '_OLD'', ''INDEX'''

IF @SORUCE_UNIQUE_INDEX_NAME != ''
	PRINT 'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + '_OLD.' + @SORUCE_UNIQUE_INDEX_NAME + ''', ''' + @SORUCE_UNIQUE_INDEX_NAME + '_OLD'', ''INDEX'''


SELECT @TARGET_INDEX_COUNT = COUNT(*) FROM #TARGET_INDEX_NAME

SET @I = 1
WHILE ( @I <= @TARGET_INDEX_COUNT )
BEGIN
		
	SELECT  @SORUCE_PK_INDEX_NAME = TARGET_NAME FROM #TARGET_INDEX_NAME WHERE SEQNO  = @I
	PRINT 'EXEC SP_RENAME ''' + REPLACE(@TARGET_TABLE_NAME, '_ETAM', '')  + '.' + @SORUCE_PK_INDEX_NAME + ''', ''' + REPLACE(@SORUCE_PK_INDEX_NAME, '_ETAM', '') + ''', ''INDEX'''

	SET @I = @I + 1
END

PRINT ''
PRINT ''
-- 13. RENAME 원복
PRINT '/**** Rollback SP_RENAME  ************************'
PRINT  'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + ''', ''' + @TARGET_TABLE_NAME + ''''
PRINT  'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + '_OLD'', ''' + @SOURCE_TABLE_NAME + ''''

PRINT ''
PRINT '--Rollback TARGET TABLE INDEX'
SET @I = 1
WHILE ( @I <= @TARGET_INDEX_COUNT )
BEGIN
		
	SELECT  @SORUCE_PK_INDEX_NAME = TARGET_NAME FROM #TARGET_INDEX_NAME WHERE SEQNO  = @I
	PRINT 'EXEC SP_RENAME ''' + @TARGET_TABLE_NAME  + '.' + REPLACE(@SORUCE_PK_INDEX_NAME, '_ETAM', '') + ''', ''' + @SORUCE_PK_INDEX_NAME + ''', ''INDEX'''

	SET @I = @I + 1
END


PRINT ''
PRINT '--Rollback SOURCE TABLE INDEX'
SET @SORUCE_PK_INDEX_NAME= ''
SELECT  @SORUCE_PK_INDEX_NAME = SOURCE_NAME
FROM #SOURCE_INDEX_NAME WHERE SOURCE_PRIMARY_KEY = 1

SET @SORUCE_UNIQUE_INDEX_NAME= ''
SELECT  @SORUCE_UNIQUE_INDEX_NAME = SOURCE_NAME
FROM #SOURCE_INDEX_NAME WHERE SOURCE_UNIQUE = 1


IF @SORUCE_PK_INDEX_NAME != ''
	PRINT 'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + '.' + @SORUCE_PK_INDEX_NAME + '_OLD'', ''' + @SORUCE_PK_INDEX_NAME + ''', ''INDEX'''


IF @SORUCE_UNIQUE_INDEX_NAME != ''
	PRINT 'EXEC SP_RENAME ''' + @SOURCE_TABLE_NAME + '.' + @SORUCE_UNIQUE_INDEX_NAME + '_OLD'', ''' + @SORUCE_UNIQUE_INDEX_NAME + ''', ''INDEX'''
PRINT '*/'

go

/*************************************************************************  
* 프로시저명: dbo.SP_DBA_CHECK_DATA_COMPARE_CHECK_SEED
* 작성정보	: 2015-09-01 BY newjisu
* 관련페이지:  dbo.SP_DBA_CHECK_DATA_COMPARE_CHECK_SEED 내부에서 Seed값 확인 프린트해줌
* 수정정보	: 

**************************************************************************/
CREATE PROC dbo.SP_DBA_CHECK_DATA_COMPARE_CHECK_SEED
  @SOURCE_DB_NAME                    SYSNAME
, @SOURCE_TABLE_NAME SYSNAME
, @TARGET_DB_NAME                    SYSNAME  = NULL
, @TARGET_TABLE_NAME SYSNAME
AS


/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @SOURCE_COUNT BIGINT = 0
DECLARE @STR_SQL  NVARCHAR(4000), @STR_PARM NVARCHAR(500)

SET @STR_SQL ='SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.SYS.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_TABLE_NAME+''') AND is_identity = 1'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

IF @SOURCE_COUNT = 0
BEGIN		
		print ''
		PRINT 'Identity Column 없음'
		print ''
		return

END
ELSE
BEGIN
		SELECT '14. identity seed check'  check_step
       print '' 
       PRINT 'Seed 값이 같은지 확인해야 합니다.'
	   PRINT 'USE ' + @SOURCE_DB_NAME+';  DBCC CHECKIDENT('''+ @SOURCE_TABLE_NAME + ''', NORESEED) ;' 
	   PRINT 'USE ' + @TARGET_DB_NAME+';  DBCC CHECKIDENT('''+ @TARGET_TABLE_NAME + ''', NORESEED) ;' 
	   PRINT '--Reseed Example'
	   PRINT '--DBCC CHECKIDENT(''테이블명'', RESEED, new_Reseed_value); ' 
	   print ''
   

END


go

/*************************************************************************  
* 프로시저명: dbo.SP_DBA_CHECK_DATA_COMPARE_SCRIPT
* 작성정보	: 2013-03-26 BY Seo Eun Mi
* 관련페이지:  
* 내용		: 테이블 이관 후 최신 데이터 위주로 컬럼별 데이터 비교 스크립트 만들어주는 SP
* 수정정보	:
**************************************************************************/
CREATE PROCEDURE [dbo].[SP_DBA_CHECK_DATA_COMPARE_SCRIPT]
	@SOURCE_DB_NAME		SYSNAME,	-- 변경전 비교 기준 DB명
	@SOURCE_DB_SCHEMA	SYSNAME,	-- 변경전 비교 스키마
	@SOURCE_TABLE_NAME	SYSNAME,	--변경전 비교 기준이 되는 테이블명
	@TARGET_DB_NAME		SYSNAME,	--변경후 비교 대상 DB명
	@TARGET_TABLE_NAME	SYSNAME,	--변경후 비교 대상이 되는 테이블명
	@SAMPLE_PERCENT INT = 5  --비교데이터 샘플링 퍼센트

AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CLUSTER_INDEX_NAME VARCHAR(500), @COUNT INT, @SOURCE_FULL_OBJECT SYSNAME, @TARGET_FULL_OBJECT SYSNAME
	DECLARE @IDX INT, @SQL NVARCHAR(4000), @FULL_SQL NVARCHAR(4000)
	DECLARE @dbcc VARCHAR(500), @rowcount INT
	DECLARE @COLUMN_NAME VARCHAR(100), @COLUMN_TYPE VARCHAR(100), @COLUMN_VALUE VARCHAR(100) 
	DECLARE @STR_SQL NVARCHAR(4000), @STR_PARM NVARCHAR(1000), @MAX_IDX INT, @SAMPLE_IDX INT
	SET @max_idx = 0

	IF @TARGET_DB_NAME IS NULL SET @TARGET_DB_NAME = @SOURCE_DB_NAME
	IF @TARGET_TABLE_NAME IS NULL SET @TARGET_TABLE_NAME = @SOURCE_TABLE_NAME + '_ETAM'

	SET @SOURCE_FULL_OBJECT = @SOURCE_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @SOURCE_TABLE_NAME
	SET @TARGET_FULL_OBJECT = @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @TARGET_TABLE_NAME

	DECLARE @object_id int
	SET @object_id = object_id(@SOURCE_FULL_OBJECT)
	IF @object_id IS NULL 
	BEGIN
		PRINT '/******** NOT Find Object ************/'
		RETURN
	END

	SET @COLUMN_VALUE = 1
	SET @COUNT = 0
	SET @IDX = 1

	SET @STR_SQL = 'SELECT TOP 1 @CLUSTER_INDEX_NAME = A.NAME ' + CHAR(10)
				 + ', @COLUMN_NAME = B.NAME,	@COLUMN_TYPE = D.name ' + CHAR(10)
				 + 'FROM ' + @SOURCE_DB_NAME + '.sys.INDEXES A (NOLOCK)' + CHAR(10)
				 + 'LEFT JOIN ' + @SOURCE_DB_NAME + '.sys.index_columns C (NOLOCK) ON A.object_id = C.object_Id  ' + CHAR(10)
				 + ' AND A.index_id = C.index_id ' + CHAR(10)
				 + 'LEFT JOIN ' + @SOURCE_DB_NAME + '.sys.COLUMNS B (NOLOCK) ON A.object_id = B.object_id AND C.column_id = B.column_id' + CHAR(10)
				 + 'LEFT JOIN ' + @SOURCE_DB_NAME + '.sys.types D (NOLOCK) ON B.user_type_id = D.user_type_id ' + CHAR(10)
				 + 'WHERE A.OBJECT_ID = OBJECT_ID(''' + @SOURCE_FULL_OBJECT + ''') AND A.INDEX_ID  = 1 ORDER BY C.key_ordinal '

	SET @STR_PARM = N'@CLUSTER_INDEX_NAME SYSNAME OUTPUT, @COLUMN_NAME SYSNAME OUTPUT, @COLUMN_TYPE SYSNAME OUTPUT'
	--PRINT @STR_SQL
	EXECUTE SP_EXECUTESQL @STR_SQL, @STR_PARM, @CLUSTER_INDEX_NAME = @CLUSTER_INDEX_NAME OUTPUT, 
			@COLUMN_NAME = @COLUMN_NAME OUTPUT, @COLUMN_TYPE = @COLUMN_TYPE OUTPUT



	
	CREATE TABLE #TEMP_MIGRATION_ROWRANGE
	(
		   IDX INT IDENTITY(1,1)
	,      RANGE_HI_KEY VARCHAR(200)
	,      RANGE_ROWS numeric(10,1)
	,      EQ_ROWS INT
	,      DISTINCT_RANGE_ROWS INT
	,      AVG_RANGE_ROWS numeric(10,6)
	)
	
	SET @dbcc = 'USE ' + @SOURCE_DB_NAME + CHAR(10)
			  + 'DBCC show_statistics (' + @SOURCE_TABLE_NAME + ', ' + @CLUSTER_INDEX_NAME + ') WITH HISTOGRAM , NO_INFOMSGS '
	
	INSERT #TEMP_MIGRATION_ROWRANGE
	EXEC(@DBCC)
	
	SELECT @MAX_IDX = max(idx) FROM #TEMP_MIGRATION_ROWRANGE	
		
	SET @SAMPLE_IDX = (@MAX_IDX * @SAMPLE_PERCENT) / 100
	
	SELECT TOP 1 @COLUMN_VALUE = RANGE_HI_KEY FROM #TEMP_MIGRATION_ROWRANGE WHERE IDX >=@MAX_IDX-@SAMPLE_IDX ORDER BY IDX 
	
	--SELECT @COLUMN_NAME,@COLUMN_TYPE,@COLUMN_VALUE,@SAMPLE_PERCENT, @MAX_IDX-@SAMPLE_PERCENT
	--SELECT * FROM #TEMP_MIGRATION_ROWRANGE
	
	IF @COLUMN_NAME IS NULL 
		PRINT 'script 추출 에러 발생! sp 확인-[SP_DBA_CHECK_DATA_COMPARE_SCRIPT]'
	
	
	SET @STR_SQL = ''
	
	
	 DECLARE @STR_SQL1 Nvarchar(4000), @STR_SQL2 Nvarchar(4000), @STR_SQL3 Nvarchar(4000)
	 SET @STR_SQL2 = ''

	 
	 SET @STR_SQL1 = N'SELECT  @STR_SQL2 =  STUFF(( SELECT  '' AND  isnull(src.'' +  name + '' ,1)''  + '' = ' +  'isnull(dest.'' +  name  + '' ,1) ''' 
	 SET @STR_SQL1 = @STR_SQL1 + N' FROM @DB.sys.columns with (nolock) '
	 SET @STR_SQL1 = @STR_SQL1 + N' WHERE  object_id = @object_id   FOR XML PATH('''')),1,1,'''')' 

	 SET @STR_SQL1 = REPLACE(@STR_SQL1 ,'@DB',@SOURCE_DB_NAME)
	 SET @STR_SQL1 = REPLACE(@STR_SQL1,'@object_id',@object_id)

	 EXEC SP_EXECUTESQL @STR_SQL1, N'@STR_SQL2 nvarchar(4000) output', @STR_SQL2 = @STR_SQL2 OUTPUT
	 		
	 SET @STR_SQL3 = CHAR(10) + 'WHERE DEST.' + @COLUMN_NAME + ' IS NULL ' 
	 
	 IF @SAMPLE_PERCENT < 100
	 BEGIN
		
		SET @STR_SQL3 = @STR_SQL3 + CHAR(10) + 'AND SRC.' + @COLUMN_NAME  + ' >= ' 
		SET @STR_SQL3 = @STR_SQL3 + CASE WHEN @COLUMN_TYPE IN ('INT', 'BIGINT') THEN @COLUMN_VALUE ELSE ''''+ @COLUMN_VALUE + '''' END
	 END
	 
	
	 SET @STR_SQL = N''  + CHAR(10) 
	    + '' + 
	    + 'SELECT SRC.@COLUMN_NAME  INTO #TMP FROM  @SOURCE_FULL_OBJECT SRC WITH(NOLOCK)'  + CHAR(10) 
		+ ' LEFT JOIN @TARGET_FULL_OBJECT  DEST WITH(NOLOCK)  ON 1=1 '   + CHAR(10) 
		+ @STR_SQL2
		+ @STR_SQL3


	 SET @STR_SQL = REPLACE(@STR_SQL,'@COLUMN_NAME',@COLUMN_NAME)
	 SET @STR_SQL = REPLACE(@STR_SQL,'@SOURCE_FULL_OBJECT',@SOURCE_FULL_OBJECT)
	 SET @STR_SQL = REPLACE(@STR_SQL,'@TARGET_FULL_OBJECT',@TARGET_FULL_OBJECT)
	 SET @STR_SQL = REPLACE(@STR_SQL,'@COLUMN_TYPE',@COLUMN_TYPE)
	 SET @STR_SQL = REPLACE(@STR_SQL,'@COLUMN_VALUE',@COLUMN_VALUE)

	 PRINT @STR_SQL
	 PRINT ''
	 PRINT 'SELECT * FROM #TMP '
	 PRINT ''


END

go
/*************************************************************************  
* 프로시저명: dbo.SP_DBA_CHECK_DATA_COMPARE
* 작성정보        : 2013-03-26 BY CHOI BO RA
* 관련페이지:  
* 내용            : 테이블 이관 후 조건 비교  
* 수정정보        : 
                           2013-06-28 서은미 unique index 또한 PK처럼 이름 변경되도록 수정
                           2013-07-04 김대경 권한체크 오류수정 ERROR_NUMBER=15330(권한이 없는 경우)
                           2013-07-09 최보라 rollback rename, 변수 초기화 추가
                           2013-07-10 노상국 INDEX 없는경우 오류 수정(index_id=0, HEAP)
                           2013-07-10 서은미 INDEX 이름에 _OLD가 있는 경우 오류 수정(replace구문에 old제거, line 133)
                           2013-07-12 최보라 스키마 바인딩 VIEW CHECK 추가
                           2013-07-25 서은미 권한 체크 try~catch source,target쪽 각각 체크하도록 오류수정
                           EXEC dbo.SP_DBA_CHECK_DATA_COMPARE 'STARDB', 'dbo', 'MOBILE_ORDER_FORM', 'STARDB', 'MOBILE_ORDER_FORM_ETAM'
**************************************************************************/
CREATE PROCEDURE [dbo].[SP_DBA_CHECK_DATA_COMPARE_SYNONYM]
         @SOURCE_DB_NAME                    SYSNAME,
         @SOURCE_DB_SCHEMA          SYSNAME,
         @SOURCE_TABLE_NAME                 SYSNAME,
         @TARGET_DB_NAME                    SYSNAME  = NULL, 
         @TARGET_TABLE_NAME                 SYSNAME  = NULL, 
         @SAMPLE                                     INT = 5

AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
DECLARE @DB_NAME  SYSNAME
DECLARE @STR_SQL  NVARCHAR(4000), @STR_PARM NVARCHAR(500)
DECLARE @SOURCE_FULL_OBJECT SYSNAME, @TARGET_FULL_OBJECT SYSNAME
DECLARE @SOURCE_COUNT BIGINT, @TARGET_COUNT BIGINT

/* BODY */

IF @TARGET_DB_NAME IS NULL SET @TARGET_DB_NAME = @SOURCE_DB_NAME
IF @TARGET_TABLE_NAME IS NULL SET @TARGET_TABLE_NAME = @SOURCE_TABLE_NAME + '_ETAM'

SET @SOURCE_FULL_OBJECT = @SOURCE_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @SOURCE_TABLE_NAME
SET @TARGET_FULL_OBJECT = @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA+ '.' + @TARGET_TABLE_NAME



-- 1. 데이터 건수 비교 
PRINT '/*** DATABASE : ' + @TARGET_DB_NAME + ' Table Name : ' + @TARGET_TABLE_NAME + ' Check Data Start ****/' 
PRINT  ''

SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0

SET @STR_SQL = 'SELECT     @SOURCE_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END     ) ' + CHAR(10)
                             +'FROM ' + @SOURCE_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL ='SELECT @TARGET_COUNT  = SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END         )  ' + CHAR(10)
                           + 'FROM ' + @TARGET_DB_NAME + '.sys.dm_db_partition_stats ps WHERE OBJECT_ID = OBJECT_ID(''' + @TARGET_FULL_OBJECT +''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         --PRINT '--1.건수 비교 : Fault 필수 확인 '
         RAISERROR ( '--1.건수 비교 : Fault 필수 확인',  16,1)     

         SELECT '1.건수 비교 ' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
END
ELSE 
         PRINT '--1.건수 비교 : OK '



-- 2.인덱스 건수 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL ='SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
SET @STR_PARM = N'@SOURCE_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT



SET @STR_SQL ='SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
SET @STR_PARM = N'@TARGET_COUNT  BIGINT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--2.인덱스 건수 비교  : Fault 필수 확인',  16,1)     
         SELECT '2.인덱스 건수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'
         EXECUTE sp_executesql  @STR_SQL

         
         SET @STR_SQL ='SELECT NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
         EXECUTE sp_executesql  @STR_SQL

END      
ELSE 
         PRINT '--2.인덱스 건수 비교 : OK'


-- 2-1. 인덱스 이름 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #SOURCE_INDEX_NAME 
( SOUCE_TABLE_NAME SYSNAME, SOURCE_NAME SYSNAME , SOURCE_TYPE  NVARCHAR(60), SOURCE_PRIMARY_KEY BIT, SOURCE_UNIQUE BIT )

CREATE TABLE #TARGET_INDEX_NAME 
( SEQNO INT IDENTITY(1,1)  NOT NULL, 
 TARGET_TABLE_NAME SYSNAME, TARGET_NAME SYSNAME , TARGET_TYPE NVARCHAR(60), TARGET_PRIMARY_KEY BIT, TARGET_UNIQUE BIT )


SET @STR_SQL ='INSERT INTO #SOURCE_INDEX_NAME' + CHAR(10)
                           +'SELECT ''' + @SOURCE_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @SOURCE_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
                           + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+''')'

EXECUTE sp_executesql  @STR_SQL


SET @STR_SQL ='INSERT INTO #TARGET_INDEX_NAME' + CHAR(10)
                           +'SELECT ''' + @TARGET_TABLE_NAME + ''',NAME, TYPE_DESC , IS_PRIMARY_KEY, IS_UNIQUE_CONSTRAINT FROM ' + @TARGET_DB_NAME +'.SYS.INDEXES ' + CHAR(10)
                           + 'WHERE INDEX_ID>0 AND OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+''')'
EXECUTE sp_executesql  @STR_SQL


SELECT @SOURCE_COUNT = COUNT(*)
FROM #SOURCE_INDEX_NAME AS A 
         --LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
         LEFT JOIN #TARGET_INDEX_NAME AS B ON A.SOURCE_NAME = REPLACE(B.TARGET_NAME, '_ETAM', '')
WHERE B.TARGET_NAME IS NULL



IF @SOURCE_COUNT > 0
BEGIN
         RAISERROR ( '--2-1.Index 이름 Check : Fault 필수 확인 ',  16,1)  
         
         SELECT A.*, B.*
         FROM #SOURCE_INDEX_NAME AS A 
                 LEFT JOIN #TARGET_INDEX_NAME AS B ON REPLACE(A.SOURCE_NAME,'_OLD', '') = REPLACE(B.TARGET_NAME, '_ETAM', '')
         WHERE B.TARGET_NAME IS NULL

END
ELSE 
         PRINT '--2-1.Index 이름 Check : OK'



-- 3. CHECK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--3.CHECK 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '3.CHECK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.check_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('+ @TARGET_FULL_OBJECT+ ')'
         EXECUTE sp_executesql  @STR_SQL
         

END
ELSE 
         PRINT '--3.CHECK 비교 : OK'

-- 4.DEFAULT 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT  OUTPUT



SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--4.DEFAULT 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '4.DEFAULT 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         
         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.default_constraints WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--4.DEFAULT 비교 : OK'



-- 5.FK 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT  OUTPUT



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--5.FK 비교  : Fault 필수 확인 ',  16,1)  
         SELECT '5.FK 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         
         SET @STR_SQL ='SELECT ''' + @SOURCE_TABLE_NAME + ''' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ''' + @TARGET_TABLE_NAME + ''' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.foreign_keys WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--5.FK 비교 : OK'

-- 6.TRIGGERS 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.triggers WHERE PARENT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
         
         RAISERROR ( '--6.Trigger 존재: 트리거명 확인',  16,1)  

         SET @STR_SQL ='SELECT ''6.Trigger 존재, DROP/CREATE 처리'' AS STEP, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.triggers WHERE PARENT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--6.Trigger 존재 하지 않음 : OK'




-- 7.권한 CHECK
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
CREATE TABLE #HELPROTECT 
( SEQNO INT IDENTITY(1,1), OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

CREATE TABLE #HELPROTECT_TARGET 
(  OWNER SYSNAME, OBJECT SYSNAME, GRANTEE SYSNAME, GRANTOR SYSNAME, PROTECTTYPE SYSNAME, [ACTION] SYSNAME, [COLUMN] SYSNAME
)

BEGIN TRY
         SET @SOURCE_COUNT = 0
         SET @STR_SQL= 'USE ' + @SOURCE_DB_NAME + CHAR(10)
                           + 'EXEC SP_HELPROTECT ' + @SOURCE_TABLE_NAME  

         INSERT INTO #HELPROTECT
         EXEC(@STR_SQL)

         SET @SOURCE_COUNT =@@ROWCOUNT 

END TRY 
BEGIN CATCH
         IF ERROR_NUMBER() = 15330 SET @SOURCE_COUNT = 0
END CATCH

BEGIN TRY
         SET @TARGET_COUNT = 0

         SET @STR_SQL= 'USE ' + @TARGET_DB_NAME + CHAR(10)
                           + 'EXEC SP_HELPROTECT ' + @TARGET_TABLE_NAME 

         INSERT INTO #HELPROTECT_TARGET
         EXEC(@STR_SQL)
         SET @TARGET_COUNT =@@ROWCOUNT
END TRY 
BEGIN CATCH
         IF ERROR_NUMBER() = 15330 SET @TARGET_COUNT = 0      
END CATCH

IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--7.권한 CHECK : Fault , 권한 생성 ',  16,1)  
         SELECT '7.권한 CHECK' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT
         PRINT ''
         
         DECLARE @I  INT
         SET @I =1
         SET @STR_SQL = ''
         WHILE ( @I <= @SOURCE_COUNT)
         BEGIN
                  
                  SELECT @STR_SQL = @STR_SQL+ 'USE ' + @TARGET_DB_NAME + CHAR(10) 
                                              + 'GRANT ' + [ACTION] + ' ON OBJECT::' + @TARGET_TABLE_NAME + ' TO ' + GRANTEE + CHAR(10)
                  FROM #HELPROTECT WHERE SEQNO = @I

                  SET @I = @I + 1
         END

         PRINT @STR_SQL
         


END
ELSE 
         PRINT '--7.권한 CHECK : OK'

-- 8.컬럼수 비교
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT 



IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--8.컬럼수 비교  : Fault 필수 확인 ',  16,1)  

         SELECT '8.컬럼수 비교' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.COLUMNS WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--8.컬럼수 비교 : OK'



-- 9.VIEW 비교 
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'
EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT


IF @SOURCE_COUNT >0 
BEGIN 
         
         RAISERROR ( '--9.VIEW 존재 : VIEW 명 확인',  16,1)  
         SET @STR_SQL ='SELECT ''9.VIEW 존재,ALTER 처리'' AS STEP, NAME FROM ' + CHAR(10)
                                   + @SOURCE_DB_NAME+ '.sys.views WHERE PARENT_OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'


         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--9.VIEW 존재 하지 않음 : OK'

-- 9-1 스미마 바인딩 된 VIEW
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies ' + CHAR(10)
                           + 'WHERE referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND CLASS > 0 AND IS_SELECTED = 1 ' + CHAR(10)
                           + ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> OBJECT_ID '
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

IF @SOURCE_COUNT >0 
BEGIN 
         
           
         SET @STR_SQL ='SELECT DISTINCT ''9.스미카 바인딩 VIEW 존재,ALTER 처리'' AS STEP, NAME' + CHAR(10)
                                   + 'FROM ' + @SOURCE_DB_NAME + '.sys.sql_dependencies AS D JOIN ' + @SOURCE_DB_NAME + '.SYS.OBJECTS AS O ON D.OBJECT_ID = O.OBJECT_ID ' + CHAR(10)
                                   + 'WHERE D.referenced_major_id = OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') AND D.CLASS > 0 AND D.IS_SELECTED = 1 ' + CHAR(10)
                                   + ' AND OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''') <> D.OBJECT_ID '
         EXECUTE sp_executesql  @STR_SQL

         RAISERROR ( '--9-1.스미카 바인딩 VIEW 존재 : VIEW 명 확인',  16,1)

END
ELSE 
         PRINT '--9-1. 스미카 바인딩 VIEW 존재 하지 않음 : OK'



--10.통계 확인 '
PRINT ''
SELECT @SOURCE_COUNT = 0, @TARGET_COUNT  = 0
SET @STR_SQL = 'SELECT @SOURCE_COUNT  = COUNT(*) FROM ' + @SOURCE_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @SOURCE_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@SOURCE_COUNT  INT OUTPUT'


EXECUTE sp_executesql @STR_SQL, @STR_PARM, @SOURCE_COUNT = @SOURCE_COUNT OUTPUT

SET @STR_SQL = 'SELECT @TARGET_COUNT  = COUNT(*) FROM ' + @TARGET_DB_NAME + '.sys.stats WHERE OBJECT_ID= OBJECT_ID(''' + @TARGET_FULL_OBJECT+ ''')  and user_created =1'
SET @STR_PARM = N'@TARGET_COUNT  INT OUTPUT'

EXECUTE sp_executesql @STR_SQL, @STR_PARM, @TARGET_COUNT = @TARGET_COUNT OUTPUT


IF @SOURCE_COUNT != @TARGET_COUNT
BEGIN 
         
         RAISERROR ( '--10.통계 확인  : Fault 필수 확인 ',  16,1)  

         SELECT '10.통계 확인' AS STEP,  @SOURCE_COUNT AS SOURCE_COUNT,  @TARGET_COUNT AS TARGET_COUNT

         SET @STR_SQL ='SELECT ' + @SOURCE_TABLE_NAME + ' AS SORUCE, NAME FROM ' + CHAR(10)
                                    + @SOURCE_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @SOURCE_FULL_OBJECT+ ''')'
                                   + ' and user_created =1'

         EXECUTE sp_executesql  @STR_SQL
         
         SET @STR_SQL ='SELECT ' + @TARGET_TABLE_NAME + ' AS TARGET, NAME FROM ' + CHAR(10)
                                   + @TARGET_DB_NAME+ '.sys.stats WHERE OBJECT_ID= OBJECT_ID('''+ @TARGET_FULL_OBJECT+ ''')'
                                   + ' and user_created =1'

         EXECUTE sp_executesql  @STR_SQL

END
ELSE 
         PRINT '--10.통계 확인 : OK'




PRINT '/****11.DATA CHECK : 쿼리 실행, 틀린 DATA 결과 나옴  *************************/'
PRINT ''

EXEC DBO.SP_DBA_CHECK_DATA_COMPARE_SCRIPT @SOURCE_DB_NAME, @SOURCE_DB_SCHEMA, 
          @SOURCE_TABLE_NAME, @TARGET_DB_NAME, @TARGET_TABLE_NAME, @SAMPLE


-- 12. 최종 확인 SP_RENAME 스크립트.
PRINT '/**** SP_RENAME  *************************/'
PRINT 'USE ' + @SOURCE_DB_NAME + ';'
PRINT 'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME + ''',''' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''''

PRINT ''

PRINT '/**** SYNONYM  *************************/'
PRINT 'CREATE SYNONYM ' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' FOR ' + @TARGET_DB_NAME + '.' + @SOURCE_DB_SCHEMA + '.' + @TARGET_TABLE_NAME

PRINT ''
PRINT ''
-- 13. RENAME 원복
PRINT '/**** Rollback SYNONYM  *************************/'
PRINT 'DROP SYNONYM ' + @SOURCE_DB_SCHEMA + '.' + @SOURCE_TABLE_NAME
PRINT ''

PRINT '/**** Rollback SP_RENAME  ************************/'
PRINT  'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''', ''' + @SOURCE_TABLE_NAME + ''''
PRINT 'USE ' + @TARGET_DB_NAME + ';'
PRINT  'EXEC SP_RENAME ''' + @SOURCE_DB_SCHEMA + '.' + @TARGET_TABLE_NAME + ''', ''' + 'UNUSED_' + @SOURCE_TABLE_NAME + ''''
PRINT ''


PRINT '*/'



go

														
														
CREATE PROC [dbo].[SP_DBA_GRANT_ACCOUNT_AUTHORITY]														
	@LOGIN_NAME SYSNAME													
	, @NEW_LOGIN_NAME SYSNAME													
	, @DB_NAME VARCHAR(200) =''													
														
AS														
BEGIN 														
	SET NOCOUNT ON													
														
	DECLARE @exec_stmt VARCHAR(MAX)													
	DECLARE @I INT													
	DECLARE @CNT INT													
	DECLARE @USER_CNT INT													
														
	IF (@DB_NAME ='')													
	BEGIN 													
		SET @I = 5												
		SET @CNT = (SELECT MAX(database_id) FROM SYS.DATABASES (NOLOCK) WHERE IS_READ_ONLY=0 AND STATE<>6 AND DATABASE_ID > 4)												
	END													
														
	ELSE													
	BEGIN													
		SET @I = (SELECT DATABASE_ID FROM SYS.DATABASES (NOLOCK) WHERE NAME = @DB_NAME)												
		SET @CNT = @I												
	END													
														
	WHILE @I <= @CNT													
	BEGIN 													
														
		SELECT @DB_NAME = NAME 												
		FROM SYS.DATABASES (NOLOCK)												
		WHERE DATABASE_ID = @I												
														
		SET @USER_CNT = 0												
		SELECT @exec_stmt  ='	  select COUNT(l.name) COUNT into ##USER_CNT											
									  from ' + quotename(@DB_NAME, '[') + '.sys.sysusers u,sys.server_principals l					
									  where u.sid  = l.sid' +					
											case 			
												when @LOGIN_NAME is null then ''		
												else ' and ( l.name = N' + quotename(@LOGIN_NAME , '''') + '		
														or l.name = N' + quotename(@LOGIN_NAME , '''') + ')'
											end			
		EXEC (@exec_stmt)												
		SELECT @USER_CNT = COUNT from ##USER_CNT												
		DROP TABLE ##USER_CNT												
														
		IF (@USER_CNT > 0)												
		BEGIN												
			PRINT 'USE ' + @DB_NAME + CHAR(10) + 'GO'											
			PRINT 'sp_change_users_login UPDATE_ONE, '''+@LOGIN_NAME +''','''+@NEW_LOGIN_NAME+''''											
			PRINT 'ALTER USER '+@LOGIN_NAME+' WITH name = '+@NEW_LOGIN_NAME											
														
		END												
														
		PRINT CHAR(10)												
		SET @I = @I + 1												
	END													
														
	PRINT 'sp_helplogins '+@NEW_LOGIN_NAME+''													
END				


go


/*====================================================================
SP명: [sp_DBA_GRANT_ROLE_MAIN] 'ed1_seom','ebaykorea\seom'
작성자: 박정우

수정사항: 노상국 20130816 check_policy, check_expiration 추가
			안지은 20140609 Window계정 변경을 위해 sp 수정
======================================================================*/
CREATE PROC [dbo].[sp_DBA_GRANT_ROLE_MAIN]
@OLD_SQL_LOGIN VARCHAR(20),
@NEW_SQL_LOGIN VARCHAR(20),
@DROP_LOGIN char(1) = 'N'

AS

BEGIN
	SET NOCOUNT ON

	DECLARE @LOGIN_SCRIPT VARCHAR(3000)
	DECLARE @IS_POLICY_CHECKED VARCHAR (3)
	DECLARE @IS_EXPIRATION_CHECKED VARCHAR (3)
	DECLARE @IS_SYSADMIN INT
	DECLARE @DEFAULTDB SYSNAME

	--서버 계정 생성 스크립트 작성
	--이미 서버에 ED1계정이 있다면 CREATE LOGIN 은 제외 
	PRINT CHAR(10) + '/*=================[' + @NEW_SQL_LOGIN + '] 생성일: ' + convert(char(19), getdate(), 121) + '==========*/' + CHAR(10)

	SELECT @DEFAULTDB = DEFAULT_DATABASE_NAME
	FROM SYS.SQL_LOGINS WITH(NOLOCK) 
	WHERE NAME = @OLD_SQL_LOGIN

	-- 로그인 생성 시작
	IF (NOT EXISTS(SELECT * FROM SYSLOGINS (NOLOCK) WHERE LOGINNAME = @NEW_SQL_LOGIN))
	BEGIN
		SET @LOGIN_SCRIPT = 'CREATE LOGIN ' + QUOTENAME(@NEW_SQL_LOGIN) + ' FROM WINDOWS WITH DEFAULT_LANGUAGE=[한국어] ' + CHAR(10)
			   
	   --디폴드 DB 입력
	    SET @LOGIN_SCRIPT = @LOGIN_SCRIPT + ', DEFAULT_DATABASE = ' + QUOTENAME(@DEFAULTDB) + CHAR(10)
		PRINT @LOGIN_SCRIPT	--서버 로그인 계정 생성 스크립트 출력
	   
	   --sysadmin  체크
		SELECT @IS_SYSADMIN= SYSADMIN FROM SYSLOGINS WHERE LOGINNAME = @OLD_SQL_LOGIN 
		IF (@IS_SYSADMIN= 1)
		BEGIN
			PRINT 'EXEC SP_ADDSRVROLEMEMBER ' + 'SYSADMIN, ' + QUOTENAME(@NEW_SQL_LOGIN)
			RETURN;   --sysadmin이면 더이상 권한체크 무의미함
		END
	END
	-- 로그인 생성끝
		
	DECLARE @SEQNO INT, @database_name VARCHAR(100), @MAX_SEQNO INT, @SQL VARCHAR(1000), @IS_READ_ONLY INT, @FINAL_SQL VARCHAR(1000)

	CREATE TABLE #database_temp		--temp 디비 만들어서 디비 목록 넣기
	(
		SEQNO INT IDENTITY(1,1),
		database_name VARCHAR(100),
		is_read_only INT
	)
	
	DECLARE @SERVER_NM sysname
	select @SERVER_NM = @@servername

	IF (@SERVER_NM = 'GCENTERDB' OR @SERVER_NM= 'GACCOUNTDB')
	BEGIN
			INSERT INTO #DATABASE_TEMP (DATABASE_NAME, IS_READ_ONLY)
			SELECT NAME,IS_READ_ONLY 
			FROM SYS.DATABASES S (NOLOCK)
			WHERE STATE <> 6 
			AND NAME NOT IN ( SELECT DBNAME FROM MASTER.DBO.TB_SYNC_DB)
			ORDER BY IS_READ_ONLY
     END
	 ELSE
	 BEGIN
	 	INSERT INTO #DATABASE_TEMP (DATABASE_NAME, IS_READ_ONLY)
		SELECT NAME,IS_READ_ONLY 
		FROM SYS.DATABASES S (NOLOCK)
		WHERE STATE <> 6
		ORDER BY IS_READ_ONLY
	 END

	IF @@ROWCOUNT > 0
	BEGIN
		SET @SEQNO = 1
		
		SELECT @MAX_SEQNO = MAX(SEQNO)
		FROM #database_temp
		
		WHILE (1=1)
		BEGIN
			SELECT @database_name = database_name, @IS_READ_ONLY = is_read_only
			FROM #database_temp
			WHERE SEQNO = @SEQNO
			
			IF @IS_READ_ONLY = 1
			BEGIN
				PRINT ''
				PRINT '*****************원본 서버에서 수행 시작*******************'
			END			
			
			
			IF(@DROP_LOGIN = 'Y')
			BEGIN
				SET @SQL = 'EXEC sp_DBA_GRANT_USER_ROLE'''+ @OLD_SQL_LOGIN + ''',''' + @NEW_SQL_LOGIN + ''', ''' + @database_name + ''', ''' + 'Y'''
			END
			ELSE
			BEGIN
				SET @SQL = 'EXEC sp_DBA_GRANT_USER_ROLE'''+ @OLD_SQL_LOGIN + ''',''' + @NEW_SQL_LOGIN + ''', ''' + @database_name + ''''
			END

			EXEC(@SQL)
			
			IF @SEQNO = @MAX_SEQNO
			BEGIN
				BREAK
			END
			SET @SEQNO = @SEQNO + 1				
			
			IF @IS_READ_ONLY = 1
			BEGIN
				PRINT '*****************원본 서버에서 수행 완료*******************'
				PRINT ''
			END
		END
		
	END

	--기존계정이 DISABLE 상태였을 때, 신규 계정도 DISABLE
	--IF(SELECT TOP 1 is_disabled FROM SYS.SERVER_PRINCIPALS  with(nolock) WHERE NAME = @OLD_SQL_LOGIN) = 1
	--BEGIN
	--	SET @SQL = 'ALTER LOGIN ' + QUOTENAME(@NEW_SQL_LOGIN) + ' DISABLE' + CHAR(10)
	--	PRINT(@SQL)
	--END

	IF(@DROP_LOGIN = 'Y')--기존계정 DROP
	BEGIN
		SET @SQL = 'DROP LOGIN ' + QUOTENAME(@OLD_SQL_LOGIN) + CHAR(10)
		PRINT(@SQL)
	END
	
	DROP TABLE #database_temp
END





go


/*====================================================================
SP명: [sp_DBA_GRANT_USER_ROLE] 
작성자: 박정우

수정사항: 20130814 schema_name 추가
          20130816 while 문 select 문으로 교체 (속도개선)
		  안지은 20140609 Window계정 변경을 위해 수정 
======================================================================*/
CREATE PROC [dbo].[sp_DBA_GRANT_USER_ROLE]
@old_sql_login VARCHAR(20),  
@new_sql_login VARCHAR(20),  
@database_name VARCHAR(100),
@drop_login CHAR(1) = 'N'

AS  

BEGIN  
	SET NOCOUNT ON  
	DECLARE @SQL VARCHAR(3000), @SEQNO INT, @MAX_SEQNO INT, @CLASS VARCHAR(20), @NAME VARCHAR(200)  

	CREATE TABLE #temp  
	(  
		SEQNO INT IDENTITY(1,1),  
		class_desc varchar(20),  
		schema_nm varchar(15),
		object_nm varchar(100),  
		name varchar(100),  
		state_desc varchar(100)  
	)  
 
	SET @SQL = 'INSERT INTO #temp  
					SELECT *  
					FROM (  
							SELECT   
							dpm.class_desc  
							, sch.name as schema_nm
							, case when dpm.major_id = 0 then ''ALL'' else obj.name end as object_nm
							, dpm.permission_name collate korean_wansung_ci_as as name   
							, dpm.state_desc  as state_desc  
							from '+@database_name+'.sys.database_principals as dpr with (nolock)  
							inner join '+@database_name+'.sys.database_permissions as dpm with (nolock) on dpr.principal_id = dpm.grantee_principal_id  
							left outer join '+@database_name+'.sys.all_objects as obj with (nolock) on dpm.major_id = obj.object_id  
							left outer join '+@database_name+'.sys.schemas as sch with(nolock) on  obj.schema_id  = sch.schema_id
							where dpr.name = ''' + @old_sql_login + '''  

							UNION ALL  
							
							SELECT   
							''ROLE'' as class_desc  
							, '''' as schema_nm
							, ''ALL''  as object_nm
							, su1.name collate korean_wansung_ci_as as name   
							, ''GRANT'' as state_desc  
							FROM '+@database_name+'.sys.sysmembers sm											
							JOIN '+@database_name+'.sys.sysusers su1 ON  sm.groupuid = su1.uid  
							JOIN '+@database_name+'.sys.sysusers su2 ON  sm.memberuid = su2.uid			
							WHERE su2.name =  ''' + @old_sql_login + '''  
					) A'  
	EXEC(@SQL)  
   
	IF @@ROWCOUNT > 0  
	BEGIN  
		PRINT 'USE [' + @database_name  + ']'
	    PRINT '--  Database  레벨 권한 체크 '
		SELECT 
			CASE WHEN NAME= 'CONNECT' THEN 'IF NOT EXISTS(SELECT * FROM SYS.SYSUSERS WITH(NOLOCK) WHERE NAME = ''' + @NEW_SQL_LOGIN +''')' + CHAR(13)
									+  'CREATE USER ' +  QUOTENAME(@NEW_SQL_LOGIN) + ' FOR LOGIN ' +  QUOTENAME(@NEW_SQL_LOGIN)
			ELSE STATE_DESC + ' ' + NAME + ' TO ' + QUOTENAME(@NEW_SQL_LOGIN) END
		FROM #TEMP  
		WHERE   CLASS_DESC = 'DATABASE'  
 
		PRINT '-- Database  레벨 권한 체크 '
  
		SELECT  'EXEC SP_ADDROLEMEMBER ''' + NAME + ''',''' + @NEW_SQL_LOGIN + ''''
		FROM #TEMP
		WHERE CLASS_DESC = 'ROLE'
  
		PRINT '-- OBJECT 레벨 권한 체크						'
		SELECT STATE_DESC + ' ' + NAME + ' ON ' +  QUOTENAME(SCHEMA_NM) + '.' +  QUOTENAME(OBJECT_NM) + ' TO ' +  QUOTENAME(@NEW_SQL_LOGIN) 
		FROM #TEMP  
		WHERE CLASS_DESC = 'OBJECT_OR_COLUMN'  
	END  
	ELSE
	BEGIN
		PRINT '--' + QUOTENAME(@database_name) + ' has not any database permission!!!'
	END
END 




go