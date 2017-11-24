

IF OBJECT_ID('UP_MON_TABLE_SPACEUSED_TERM') IS NOT NULL
	DROP PROCEDURE UP_MON_TABLE_SPACEUSED_TERM
GO

CREATE PROCEDURE UP_MON_TABLE_SPACEUSED_TERM
AS
BEGIN
SET NOCOUNT ON

declare @min_value datetime, @max_value datetime, @new_value datetime

select @min_value = min(CONVERT(datetime, value)), @max_value = max(CONVERT(datetime, value))
from sys.partition_range_values v JOIN sys.partition_functions f ON v.function_id = f.function_id
where f.name = 'PF_MON_TABLE_SPACEUSED_TERM'

if @max_value < GETDATE()
begin
	
	SET @new_value = DATEADD(day, 10, @max_value)

	-- 1 번파티션을TESTDATA_BAK 으로이관
	ALTER TABLE DB_MON_TABLE_SPACEUSED_TERM SWITCH PARTITION 1 TO DB_MON_TABLE_SPACEUSED_TERM_TEMP

	-- TESTDATA_BAK 을모두지움
	TRUNCATE TABLE DB_MON_TABLE_SPACEUSED_TERM_TEMP

	-- 다음 사용 PARTITION 을지정
	ALTER PARTITION SCHEME PS_MON_TABLE_SPACEUSED_TERM NEXT USED [PRIMARY]

	-- 기존의1 번파티션과2번파티션을MERGE
	ALTER PARTITION FUNCTION PF_MON_TABLE_SPACEUSED_TERM() MERGE RANGE (@min_value)

	-- 새로운파티션생성
	ALTER PARTITION FUNCTION PF_MON_TABLE_SPACEUSED_TERM() SPLIT RANGE (@new_value)

end

declare @now datetime, @lastday datetime

select top 1 @now = now from DB_MON_TABLE_SPACEUSED (nolock) order by now desc

select dbname, objectname, rows, reserved
into #DB_MON_TABLE_SPACEUSED_NOW
from DB_MON_TABLE_SPACEUSED (nolock)
where now = @now

select top 1 @lastday = now from DB_MON_TABLE_SPACEUSED (nolock) where now < @now order by now desc

IF @lastday IS NULL return

select dbname, objectname, rows, reserved
into #DB_MON_TABLE_SPACEUSED_LASTDAY
from DB_MON_TABLE_SPACEUSED (nolock)
where now = @lastday


insert dbo.DB_MON_TABLE_SPACEUSED_TERM(now, dbname, objectname, rows, reserved, row_change, reserved_change, row_change_day, reserved_change_day, term_min)
select @now, 
	now.dbname, 
	now.objectname,
	now.rows,
	now.reserved,
	(now.rows - ISNULL(last.rows, 0)) AS row_change,
	(now.reserved - isnull(last.reserved, 0)) as reserved_change,
	((now.rows - isnull(last.rows, 0)) * 24 * 60) / DATEDIFF(MINUTE, @lastday, @now) as row_change_day,
	((now.reserved - isnull(last.reserved, 0)) * 24 * 60) / DATEDIFF(MINUTE, @lastday, @now) as row_change_day,
	DATEDIFF(MINUTE, @lastday, @now) as term_min
from #DB_MON_TABLE_SPACEUSED_NOW now (NOLOCK)
	LEFT JOIN #DB_MON_TABLE_SPACEUSED_LASTDAY last (nolock) ON now.dbname = last.dbname AND now.objectname = last.objectname

END
