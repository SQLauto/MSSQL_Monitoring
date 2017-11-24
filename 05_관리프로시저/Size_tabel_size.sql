SET NOCOUNT ON

CREATE TABLE #TBLSize
 (Tblname varchar(80), 
 TblRows int,
 TblReserved varchar(80),
 TblData varchar(80),
 TblIndex_Size varchar(80),
 TblUnused varchar(80))

DECLARE @DBname varchar(80) 
DECLARE @tablename varchar(80) 

SELECT @DBname = DB_NAME(DB_ID())
PRINT 'User Table size Report for (Server / Database):   ' + @@ServerName + ' / ' + @DBName
PRINT ''
PRINT 'By Size Descending'
DECLARE TblName_cursor CURSOR FOR 
SELECT NAME 
FROM sysobjects
WHERE xType = 'U'

OPEN TblName_cursor

FETCH NEXT FROM TblName_cursor 
INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
   INSERT INTO #tblSize(Tblname, TblRows, TblReserved, TblData, TblIndex_Size, TblUnused)
   EXEC Sp_SpaceUsed @tablename
      
   -- Get the next author.
   FETCH NEXT FROM TblName_cursor 
   INTO @tablename
END

CLOSE TblName_cursor
DEALLOCATE TblName_cursor

SELECT  CAST(Tblname as Varchar(30)) 'Table',
	CAST(TblRows as Varchar(14)) 'Row Count',
	CAST(LEFT(TblReserved, CHARINDEX(' KB', TblReserved)) as int) 'Total Space (KB)',
        CAST(TblData as Varchar(14)) 'Data Space',
	CAST(TblIndex_Size  as Varchar(14)) 'Index Space',
        CAST(TblUnused as Varchar(14)) 'Unused Space'
FROM #tblSize
Order by 'Total Space (KB)' Desc

PRINT ''
PRINT 'By Table Name Alphabetical'


SELECT  CAST(Tblname as Varchar(30)) 'Table',
	CAST(TblRows as Varchar(14)) 'Row Count',
	CAST(LEFT(TblReserved, CHARINDEX(' KB', TblReserved)) as int) 'Total Space (KB)',
        CAST(TblData as Varchar(14)) 'Data Space',
	CAST(TblIndex_Size  as Varchar(14)) 'Index Space',
        CAST(TblUnused as Varchar(14)) 'Unused Space'
FROM #tblSize
Order by 'Table'


--EXEC sp_spaceused 'Categories' 