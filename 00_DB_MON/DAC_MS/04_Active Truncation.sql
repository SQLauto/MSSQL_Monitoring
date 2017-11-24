use dbmon
go
DECLARE @FromTime DATETIME = '2017-01-12 17:26:21.223'
DECLARE @ToTime DATETIME = '2017-01-12 17:26:52.833'

select runtime, count(*) as session_id
FROM DB_MON_MS_DAC_TRANSACTIONS (nolock)
where runtime between @fromtime and @totime
group by runtime
go

DECLARE @FromTime DATETIME = '2017-01-12 17:26:21.223'
DECLARE @ToTime DATETIME = '2017-01-12 17:26:52.833'

select runtime, wait_type, count(*) as cnt, sum(wait_duration_ms) as waits_ms
FROM DB_MON_MS_DAC_TRANSACTIONS (nolock)
where runtime between @FromTime and @ToTime
group by runtime, wait_type
order by wait_type, runtime
go