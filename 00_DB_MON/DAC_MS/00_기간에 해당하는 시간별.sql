USE DBMON
GO

-- 해당 구간 동안 집계 내역, 시간 별 순위
DECLARE @StartTime DATETIME = '2017-01-12 17:26:21.223'
DECLARE @EndTime DATETIME = '2017-01-12 17:26:52.833'

DECLARE @tbl_atime TABLE (
	id INT IDENTITY(1,1),
	runtime DATETIME);
DECLARE @tbl_btime TABLE (
	id INT IDENTITY(1,1),
	runtime DATETIME);

DECLARE @begin_set TABLE (
	id	INT,
	runtime DATETIME,
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
	id	INT,
	runtime DATETIME,
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

-- Time Table Insert
INSERT INTO @tbl_atime
SELECT DISTINCT runtime
FROM DB_MON_MS_DAC_REQUEST (nolock)
WHERE runtime BETWEEN @StartTime AND @EndTime




-- Tiem Table Insert
INSERT INTO @tbl_btime
SELECT DISTINCT runtime
FROM DB_MON_MS_DAC_REQUEST (nolock)
WHERE runtime BETWEEN @StartTime AND @EndTime
AND runtime <> (SELECT min(runtime) FROM @tbl_atime)
ORDER BY runtime


INSERT INTO @begin_set
SELECT	b.id,
		a.runtime,
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
	 INNER JOIN @tbl_atime b ON a.runtime = b.runtime 
--WHERE a.session_id = 6874

INSERT INTO @end_set
SELECT	b.id,
		a.runtime,
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
	 INNER JOIN @tbl_btime b ON a.runtime = b.runtime
--WHERE a.session_id = 6874
	 
SELECT
		bset.runtime,
		bset.session_id,
		bset.request_start_time,
		(eset.request_cpu_time - bset.request_cpu_time) as request_cpu_time,
		(eset.request_logical_reads - bset.request_logical_reads) as request_logical_reads,
		(eset.request_reads - bset.request_reads) as request_reads,
		(eset.request_writes - bset.request_writes) as request_writes,
		bset.plan_handle, eset.plan_handle
		--bset.statement_start_offset,
		--bset.statement_end_offset
FROM	@begin_set as bset
		INNER JOIN @end_set as eset
			ON	bset.id = eset.id
			AND bset.session_id = eset.session_id
			AND bset.request_start_time = eset.request_start_time
ORDER BY bset.runtime
go