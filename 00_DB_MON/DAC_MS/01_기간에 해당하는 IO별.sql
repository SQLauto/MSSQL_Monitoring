USE DBMON
go

DECLARE @FromTime DATETIME = '2016-07-11 15:54:24.320'
DECLARE @ToTime DATETIME = '2016-07-11 15:54:59.317'

DECLARE @StartTime DATETIME
DECLARE @EndTime DATETIME

DECLARE @tbl_atime TABLE (
	id INT IDENTITY(1,1),
	runtime DATETIME);
DECLARE @tbl_btime TABLE (
	id INT IDENTITY(1,1),
	runtime DATETIME);

DECLARE @begin_set TABLE (
	session_id INT, 
	request_cpu_time BIGINT, 
	request_logical_reads BIGINT,
	request_reads BIGINT,
	request_writes BIGINT,
	request_start_time DATETIME,
	plan_handle VARBINARY(64),
	statement_start_offset INT,
	statement_end_offset INT
);

DECLARE @end_set TABLE (
	session_id INT, 
	request_cpu_time BIGINT, 
	request_logical_reads BIGINT,
	request_reads BIGINT,
	request_writes BIGINT,
	request_start_time DATETIME,
	plan_handle VARBINARY(64),
	statement_start_offset INT,
	statement_end_offset INT
);

SELECT	@StartTime = MIN(runtime),
		@EndTime = MAX(runtime)
FROM DB_MON_MS_DAC_REQUEST (nolock)
WHERE runtime BETWEEN @FromTime AND @ToTime

SELECT DATEDIFF(s, @StartTime, @EndTime)

IF DATEDIFF(s, @StartTime, @EndTime) = 0
BEGIN
	PRINT 'no Time gap'
END
ELSE
BEGIN
	INSERT INTO @begin_set
	SELECT	
			a.session_id, 
			ISNULL(a.request_cpu_time,0) as request_cpu_time, 
			ISNULL(a.request_logical_reads,0) as request_logical_reads,
			ISNULL(a.request_reads,0) as request_reads,
			ISNULL(a.request_writes,0) as request_writes,
			a.request_start_time,
			a.plan_handle,
			a.statement_start_offset,
			a.statement_end_offset
	FROM DB_MON_MS_DAC_REQUEST (nolock) a
	WHERE a.runtime = @StartTime 

	INSERT INTO @end_set
	SELECT	
			a.session_id, 
			ISNULL(a.request_cpu_time,0) as request_cpu_time, 
			ISNULL(a.request_logical_reads,0) as request_logical_reads,
			ISNULL(a.request_reads,0) as request_reads,
			ISNULL(a.request_writes,0) as request_writes,
			a.request_start_time,
			a.plan_handle,
			a.statement_start_offset,
			a.statement_end_offset
	FROM DB_MON_MS_DAC_REQUEST (nolock) a
	WHERE a.runtime = @EndTime 

	SELECT
			bset.session_id,
			bset.request_start_time,
			(eset.request_cpu_time - bset.request_cpu_time) as request_cpu_time,
			(eset.request_logical_reads - bset.request_logical_reads) as request_logical_reads,
			(eset.request_reads - bset.request_reads) as request_reads,
			(eset.request_writes - bset.request_writes) as request_writes,
			bset.plan_handle, 
			bset.statement_start_offset,
			bset.statement_end_offset
	FROM	@begin_set AS bset
			INNER JOIN @end_set AS eset 
				ON bset.session_id = eset.session_id
				AND bset.request_start_time = eset.request_start_time
	ORDER BY request_logical_reads DESC
END

/**
select reg_date, cnt_total,cpu_cnt,reads_cnt from [dbo].[DB_MON_QUERY_STATS_V3] (nolock) 
where reg_date > '2016-07-10'
and plan_handle = 0x05000C005EF87C554081E1C1030000000000000000000000
and statement_start = 4184 and statement_end = 22474
order by reg_date 
**/