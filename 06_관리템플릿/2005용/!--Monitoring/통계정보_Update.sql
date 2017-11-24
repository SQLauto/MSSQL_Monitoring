-- ==============================
-- 통계정보 Update
-- =============================


--1. SQL 2000용
select object_name(id), indid, stats_date(id, indid) from sysindexes where id = object_id('aa')


SET NOCOUNT ON


DECLARE @tablename VARCHAR (128)
DECLARE @execstr   VARCHAR (255)

SELECT object_name(id) AS TableName
INTO #TableName
FROM sysindexes 
WHERE id > 100 and indid < 2 and rowmodctr > 0.05 * rows and rows > 1000000

DECLARE tbname CURSOR FOR
   SELECT TableName
   FROM #TableName

OPEN tbname

FETCH NEXT
   FROM tbname
   INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
   SELECT @execstr = 'update statistics ' + '['+RTRIM(@tablename)+']' 
   EXEC (@execstr)

   FETCH NEXT
      FROM tbname
      INTO @tablename
END

CLOSE tbname
DEALLOCATE tbname

DROP TABLE #TableName

SET NOCOUNT OFF
GO
