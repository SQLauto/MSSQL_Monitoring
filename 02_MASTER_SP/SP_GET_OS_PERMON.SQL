
/*************************************************************************  
* 프로시저명: dbo.SP_GET_OS_PERFMON
* 작성정보	: 2013-07-10 by choi bo ra
* 관련페이지:  
* 내용		: SQL 성능 COUNTER SP
**************************************************************************/
CREATE PROC SP_GET_OS_PERFMON
AS
SET NOCOUNT ON;
 
-- Variables for Counters
DECLARE @BatchRequestsPerSecond BIGINT;
DECLARE @CompilationsPerSecond BIGINT;
DECLARE @ReCompilationsPerSecond BIGINT;
DECLARE @LockWaitsPerSecond BIGINT;
DECLARE @PageSplitsPerSecond BIGINT;
DECLARE @CheckpointPagesPerSecond BIGINT;
 
-- Variable for date
DECLARE @stat_date DATETIME;
 
-- Table for First Sample
DECLARE @RatioStatsX TAbLE(
       [object_name] varchar(128)
      ,[counter_name] varchar(128)
      ,[instance_name] varchar(128)
      ,[cntr_value] bigint
      ,[cntr_type] int
      )
 
-- Table for Second Sample
DECLARE @RatioStatsY TABLE(
       [object_name] VARCHAR(128)
      ,[counter_name] VARCHAR(128)
      ,[instance_name] VARCHAR(128)
      ,[cntr_value] BIGINT
      ,[cntr_type] INT
      );

DECLARE @RatioStatsL TABLE(
       [object_name] VARCHAR(128)
      ,[counter_name] VARCHAR(128)
      ,[instance_name] VARCHAR(128)
      ,[cntr_value] BIGINT
      ,[cntr_type] INT
      );
 
-- Capture stat time
SET @stat_date = getdate();
 
INSERT INTO @RatioStatsX (
     [object_name]
      ,[counter_name]
      ,[instance_name]
      ,[cntr_value]
      ,[cntr_type] )
      SELECT [object_name]
            ,[counter_name]
            ,[instance_name]
            ,[cntr_value]
            ,[cntr_type] FROM sys.dm_os_performance_counters;
 
-- Capture each per second counter for first sampling
SELECT TOP 1 @BatchRequestsPerSecond = cntr_value
      FROM @RatioStatsX
    WHERE counter_name = 'Batch Requests/sec'
      AND object_name LIKE '%SQL Statistics%';
 
SELECT TOP 1 @CompilationsPerSecond = cntr_value
      FROM @RatioStatsX
    WHERE counter_name = 'SQL Compilations/sec'
      AND object_name LIKE '%SQL Statistics%';
 
SELECT TOP 1 @ReCompilationsPerSecond = cntr_value
      FROM @RatioStatsX
    WHERE counter_name = 'SQL Re-Compilations/sec'
      AND object_name LIKE '%SQL Statistics%';
 
SELECT TOP 1 @LockWaitsPerSecond = cntr_value
      FROM @RatioStatsX
    WHERE counter_name = 'Lock Waits/sec'
      AND instance_name = '_Total'
      AND object_name LIKE '%Locks%';
 
SELECT TOP 1 @PageSplitsPerSecond = cntr_value
      FROM @RatioStatsX
    WHERE counter_name = 'Page Splits/sec'
      AND object_name LIKE '%Access Methods%'; 
 
SELECT TOP 1 @CheckpointPagesPerSecond = cntr_value
      FROM @RatioStatsX
      WHERE counter_name = 'Checkpoint Pages/sec'
        AND object_name LIKE '%Buffer Manager%';                                         
 
WAITFOR DELAY '00:00:01'
 
-- Table for second sample
INSERT INTO @RatioStatsY (
            [object_name]
            ,[counter_name]
            ,[instance_name]
            ,[cntr_value]
            ,[cntr_type] )
   SELECT [object_name]
            ,[counter_name]
            ,[instance_name]
            ,[cntr_value]
            ,[cntr_type] 
   FROM sys.dm_os_performance_counters


INSERT INTO @RatioStatsL
SELECT  * FROM @RatioStatsY
WHERE COUNTER_NAME  = 'User Connections'

INSERT INTO @RatioStatsL
SELECT 'SQLServer:SQL Statistic','Batch Requests/sec', NULL 
  , (cntr_value - @BatchRequestsPerSecond) /
                     (CASE WHEN datediff(ss,@stat_date, getdate()) = 0
                           THEN  1
                           ELSE datediff(ss,@stat_date, getdate()) END) AS [BatchRequestsPerSecond]
, 1073939712
  FROM @RatioStatsY
  WHERE counter_name = 'Batch Requests/sec'
 AND object_name LIKE '%SQL Statistics%'


INSERT INTO @RatioStatsL
SELECT 'SQLServer:Buffer Manager','Buffer cache hit ratio' ,  null
	,(a.cntr_value * 1.0 / b.cntr_value) * 100.0 [BufferCacheHitRatio]
	,1073939712
FROM (SELECT * FROM @RatioStatsY 
        WHERE counter_name = 'Buffer cache hit ratio'
          AND object_name LIKE '%:Buffer Manager%') a  
    CROSS JOIN
     (SELECT * FROM sys.dm_os_performance_counters  
        WHERE counter_name = 'Buffer cache hit ratio base'
          and object_name LIKE '%:Buffer Manager%') b 

INSERT INTO @RatioStatsL
SELECT  * FROM @RatioStatsY
WHERE COUNTER_NAME  IN (
	  'Processes blocked'
	, 'Memory Grants Outstanding'
	, 'Granted Workspace Memory (KB)'
	, 'Full Scans/sec'
	, 'Index Searches/sec')

INSERT INTO @RatioStatsL
SELECT  * FROM @RatioStatsY
WHERE COUNTER_NAME  ='Page life expectancy'
	AND OBJECT_NAME  = '%:Buffer Manager%'

INSERT INTO @RatioStatsL
SELECT 'SQLServer:SQL Statistic','SQL Compilations/sec',    null
  , (cntr_value - @CompilationsPerSecond) /
                     (CASE WHEN datediff(ss,@stat_date, getdate()) = 0
                           THEN  1
                           ELSE datediff(ss,@stat_date, getdate()) END)
, 1073939712
  FROM @RatioStatsY
  WHERE counter_name = 'SQL Compilations/sec' 
 AND object_name LIKE '%SQL Statistics%'

INSERT INTO @RatioStatsL
SELECT 'SQLServer:SQL Statistic','SQL Re-Compilations/sec',  null
  , (cntr_value - @ReCompilationsPerSecond) /
                     (CASE WHEN datediff(ss,@stat_date, getdate()) = 0
                           THEN  1
                           ELSE datediff(ss,@stat_date, getdate()) END)
, 1073939712
  FROM @RatioStatsY
  WHERE counter_name = 'SQL Re-Compilations/sec'
 AND object_name LIKE '%SQL Statistics%'

 INSERT INTO @RatioStatsL
 SELECT 'SQLServer:SQL Statistic','Lock Waits/sec',  '_Total'
  , (cntr_value - @LockWaitsPerSecond) /
                     (CASE WHEN datediff(ss,@stat_date, getdate()) = 0
                           THEN  1
                           ELSE datediff(ss,@stat_date, getdate()) END)
, 1073939712
  FROM @RatioStatsY
  WHERE counter_name = 'Lock Waits/sec'  AND instance_name = '_Total'
	AND object_name LIKE '%Locks%'
	

 INSERT INTO @RatioStatsL
 SELECT 'SQLServer:Buffer Manager', 'Checkpoint Pages/sec',  '_Total'
  , (cntr_value - @CheckpointPagesPerSecond) /
                     (CASE WHEN datediff(ss,@stat_date, getdate()) = 0
                           THEN  1
                           ELSE datediff(ss,@stat_date, getdate()) END)
, 272696576
  FROM @RatioStatsY
  WHERE counter_name = 'Checkpoint Pages/sec' 
	AND object_name LIKE '%Buffer Manager%'

select * from @RatioStatsL