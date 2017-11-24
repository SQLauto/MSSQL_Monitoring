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

-- 실행방법
--EXEC sp_stop_trace @TraceId, NULL
--EXEC sp_Stop_tace NULL, 'c:\test.trc'