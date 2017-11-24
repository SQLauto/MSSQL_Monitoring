-- 1. 지정 시간동안 계속 수행되는 Batch 집계

/**
07/11/2016 10:37:41.773
07/11/2016 10:38:19.766

**/

DECLARE @FromTime DATETIME = '2016-07-11 10:37:41.773'
DECLARE @ToTime DATETIME = '2016-07-11 10:38:19.766'

/**
SELECT	MIN(runtime),
		MAX(runtime)
FROM DB_MON_MS_DAC_REQUEST (nolock)
WHERE runtime BETWEEN @FromTime AND @ToTime
**/

DECLARE @StartTime DATETIME
DECLARE @EndTime DATETIME
DECLARE @LastTime DATETIME

DECLARE @tbl_atime TABLE (
	id INT IDENTITY(1,1),
	runtime DATETIME);
	
DECLARE @begin_set TABLE (
	session_id INT,
	ecid INT, 
	request_cpu_time BIGINT, 
	request_logical_reads BIGINT,
	request_reads BIGINT,
	request_writes BIGINT,
	request_start_time DATETIME,
	plan_handle VARBINARY(64),
	statement_start_offset INT,
	statement_end_offset INT,
	request_total_elapsed_time BIGINT,
	last_request_start_time DATETIME,
	last_request_end_time DATETIME,
	program_name NVARCHAR(600)
);

DECLARE @end_set TABLE (
	session_id INT, 
	ecid INT,
	request_cpu_time BIGINT, 
	request_logical_reads BIGINT,
	request_reads BIGINT,
	request_writes BIGINT,
	request_start_time DATETIME,
	plan_handle VARBINARY(64),
	statement_start_offset INT,
	statement_end_offset INT,
	request_total_elapsed_time BIGINT,
	last_request_start_time DATETIME,
	last_request_end_time DATETIME,
	program_name NVARCHAR(600)
);

DECLARE @result_set TABLE (
	start_time DATETIME,
	end_time DATETIME,
	interval INT,
	session_id INT, 
	request_start_time DATETIME,
	request_cpu_time BIGINT, 
	request_logical_reads_MB BIGINT,
	request_reads BIGINT,
	request_writes BIGINT,
	plan_handle VARBINARY(64),
	statement_start_offset INT,
	statement_end_offset INT,
	program_name NVARCHAR(600),
	request_total_elapsed_time BIGINT
);

-- Time Table  생성
INSERT INTO @tbl_atime
SELECT DISTINCT runtime
FROM DB_MON_MS_DAC_REQUEST (nolock)
WHERE runtime BETWEEN @FromTime AND @ToTime
ORDER BY runtime

-- 1st Start Time
SELECT	@StartTime = MIN(runtime),		--2016-07-11 15:54:25.843
		@LastTime = MAX(runtime)		--2016-07-11 15:54:51.953
FROM @tbl_atime
WHERE runtime BETWEEN @FromTime AND @ToTime

-- 1st End Time
SELECT @EndTime = MIN(runtime)			--2016-07-11 15:54:31.603
FROM @tbl_atime
WHERE runtime > @StartTime

-- until last time of table table
WHILE @StartTime <> @LastTime
BEGIN
	
	-- DB_MON_MS_DAC_REQUEST of @StartTime
	INSERT INTO @begin_set
	SELECT	
			a.session_id, 
			a.ecid,
			ISNULL(a.request_cpu_time,0) as request_cpu_time, 
			ISNULL(a.request_logical_reads,0) as request_logical_reads,
			ISNULL(a.request_reads,0) as request_reads,
			ISNULL(a.request_writes,0) as request_writes,
			a.request_start_time,
			a.plan_handle,
			a.statement_start_offset,
			a.statement_end_offset,
			a.request_total_elapsed_time,
			a.last_request_start_time,
			a.last_request_end_time,
			a.program_name
	FROM DB_MON_MS_DAC_REQUEST (nolock) a
	WHERE a.runtime = @StartTime 
	--AND a.ecid = 0

	-- DB_MON_MS_DAC_REQUEST of @EndTime
	INSERT INTO @end_set
	SELECT	
			a.session_id, 
			a.ecid,
			ISNULL(a.request_cpu_time,0) as request_cpu_time, 
			ISNULL(a.request_logical_reads,0) as request_logical_reads,
			ISNULL(a.request_reads,0) as request_reads,
			ISNULL(a.request_writes,0) as request_writes,
			a.request_start_time,
			a.plan_handle,
			a.statement_start_offset,
			a.statement_end_offset,
			a.request_total_elapsed_time,
			a.last_request_start_time,
			a.last_request_end_time,
			a.program_name
	FROM DB_MON_MS_DAC_REQUEST (nolock) a
	WHERE a.runtime = @EndTime 
	--AND a.ecid = 0

	-- Difference between @StartTime and @EndTime
	INSERT INTO @result_set
	SELECT
			@StartTime as StartTime,
			@EndTime as EndTime,
			DATEDIFF(s,@StartTime,@EndTime) as Interval,
			bset.session_id,
			bset.request_start_time,
			(eset.request_cpu_time - bset.request_cpu_time) as request_cpu_time,
			(eset.request_logical_reads - bset.request_logical_reads) * 8 / 1024 as request_logical_reads_MB,
			(eset.request_reads - bset.request_reads) as request_reads,
			(eset.request_writes - bset.request_writes) as request_writes,
			bset.plan_handle, 
			bset.statement_start_offset,
			bset.statement_end_offset,
			bset.program_name,
			eset.request_total_elapsed_time
			--bset.request_logical_reads,
			--eset.request_logical_reads
	FROM	@begin_set AS bset
			INNER JOIN @end_set AS eset 
				ON bset.session_id = eset.session_id
				AND bset.request_start_time = eset.request_start_time
	AND bset.ecid = 0 AND eset.ecid = 0
	AND (eset.request_logical_reads - bset.request_logical_reads) > 128		-- 1MB 이상 차이
	ORDER BY request_logical_reads_MB DESC

	-- Next @StartTime
	SET @StartTime = @EndTime					--2016-07-11 15:54:31.603		2016-07-11 15:54:37.800		2016-07-11 15:54:51.953
	
	-- Next @EndTime
	SELECT @EndTime = MIN(runtime)				--2016-07-11 15:54:37.800		2016-07-11 15:54:51.953
	FROM @tbl_atime
	WHERE runtime > @StartTime

	DELETE FROM @begin_set
	DELETE FROM @end_set
END

-- 수집시간별 총 집계
SELECT	start_time,
		end_time,
		interval,
		SUM(request_cpu_time) / 1000 AS CPU_SEC,
		SUM(request_logical_reads_MB) AS READS_MB
FROM @result_set
GROUP BY start_time, end_time, interval

-- 세션별 집계
SELECT
		session_id,
		request_start_time,
		SUM(request_cpu_time) AS CPU_MS,
		SUM(request_logical_reads_MB) AS READS_MB,
		program_name,
		plan_handle, 
		statement_start_offset,
		statement_end_offset
FROM	@result_set
GROUP BY session_id,
		request_start_time,
		plan_handle, 
		statement_start_offset,
		statement_end_offset,
		program_name
ORDER BY READS_MB DESC




