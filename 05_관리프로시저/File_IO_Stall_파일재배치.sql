SET NOCOUNT ON

CREATE TABLE #temp_sysfilegroups
(	seq_no INT IDENTITY(1,1)
,	dbid INT
,	database_name VARCHAR(100)
,	filegroupid INT
,	filegroupname VARCHAR(100)
)

DECLARE @min_seq_no INT, @max_seq_no INT, @db_id INT
DECLARE @sqltext NVARCHAR(1024), @db_name VARCHAR(100)
SELECT IDENTITY(INT, 1, 1) as seq_no, database_id, name into #tmp
FROM sys.databases WITH(NOLOCK) WHERE state = 0

SELECT @min_seq_no = MIN(seq_no), @max_seq_no = MAX(seq_no) FROM #tmp

WHILE (@min_seq_no <= @max_seq_no)
BEGIN
	SELECT @db_name = name, @db_id = database_id FROM #tmp WITH(NOLOCK) WHERE seq_no = @min_seq_no
	SET @sqltext = 
		N'INSERT #temp_sysfilegroups(dbid, database_name, filegroupid, filegroupname) 
	SELECT '+CONVERT(VARCHAR(10), @db_id)+' as dbid, '''+@db_name+''' as database_name, data_space_id, name 
	FROM '+@db_name+'.sys.filegroups
	UNION SELECT '+CONVERT(VARCHAR(10), @db_id)+' as dbid, '''+@db_name+''' as database_name, 0, name FROM master..sysaltfiles where dbid='+CONVERT(VARCHAR(10), @db_id)+' and groupid=0'
--	SELECT @sqltext
	EXEC sp_executesql @sqltext

	SET @min_seq_no = @min_seq_no + 1

END



--======================================================================================
--¿¢¼¿ÆÄÀÏ Äõ¸®
--======================================================================================
select  db_name(b.dbid) as database_name, b.name as LogicalFileName,
     b.size * 8 /1024 as sizeMB, c.filegroupname, a.io_stall_read_ms, a.io_stall_read_ms,
     Upper(left(b.filename, 1)) as before_disk,  Upper(left(b.filename, 1)) as after_disk,
     '' as is_change,
     b.growth * 8 /1024 as growth, b.filename
from sys.dm_io_virtual_file_stats( null, null) as a
    join master..sysaltfiles as b on a.database_id = b.dbid and a.file_id = b.fileid
    JOIN #temp_sysfilegroups c with(nolock) ON b.dbid = c.dbid and b.groupid = c.filegroupid
    
    

DROP TABLE #temp_sysfilegroups

DROP TABLE #tmp

