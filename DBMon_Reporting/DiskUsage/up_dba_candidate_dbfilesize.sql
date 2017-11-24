/*************************************************************************  
* 프로시저명  : dbo.up_dba_candidate_dbfilesize 
* 작성정보    : 2009-07-30 by choi bo ra
* 관련페이지  : 레포팅 서비스 디스크 용량 계산
* 내용        :
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_candidate_dbfilesize
     @target      DECIMAL(5,2)
AS
/* COMMON DECLARE */
SET NOCOUNT ON


/* USER DECLARE */
DECLARE	@cmd varchar(1000)          -- various commands
DECLARE	@counter tinyint            -- Number of databases
DECLARE	@crlf char(2)               -- carriage return line feed
DECLARE	@db sysname                 -- Database Name

SET		@crlf = CHAR(13) + CHAR(10)
SET		@target = convert(DECIMAL(5,2) , ((100.0 - @target) * .01))

/* BODY */
--
--IF OBJECT_ID('#Results') IS NOT NULL DROP TABLE #Results
--CREATE TABLE #Results (
--	DBName sysname,
--	[FileName] sysname,
--	FileType sysname,
--	Drive char(1),
--	UsedData decimal(10,2), --varchar(25),
--	TotalDataSize  decimal(10,2), --varchar(25),
--	Smallest decimal(10,2)
--	)
--

truncate table DB_FILE_SIZE


-- Databases to examine
DECLARE @Databases TABLE  (
	DID tinyint IDENTITY(1,1) primary key,
	db sysname NULL
	)

-- Hold values from xp_fixeddrives
DECLARE @DiskInfo TABLE(
	Drive char(1) primary key,
	MBFree int
	)

-- Gather databases
INSERT @Databases
SELECT	DISTINCT sd.[name]
FROM	sys.master_files mf WITH (NOLOCK)
JOIN	sys.databases sd WITH (NOLOCK)
ON		mf.database_id = sd.database_id
WHERE	sd.[state] = 0
AND		sd.is_read_only = 0
AND		sd.is_in_standby = 0
AND		sd.[name] NOT IN ('model',  'msdb', 'master')
AND		mf.[type] = 0
-- to exclude databases that have a full text-catalog offline
AND		sd.database_id NOT IN (
                            SELECT DISTINCT database_id
                            FROM  sys.master_files WITH (NOLOCK)
                            WHERE [state] <> 0)

SET		@counter = SCOPE_IDENTITY()


WHILE	@counter > 0
BEGIN
		SELECT      @db = db
		FROM  @Databases
		WHERE DID = @counter    

		SELECT @cmd = 

		N'USE [' + @db + N']' +  @crlf + 
		N'SET NOCOUNT ON' + @crlf + 
		N'SELECT     '+ QUOTENAME(@db, '''') + N',' + @crlf + 
		N'[name],' + @crlf + 
		N'CASE type ' + @crlf + 
		N'     WHEN 0 THEN ''DATA''' + @crlf + 
		N'     WHEN 1 THEN ''LOG'''  + @crlf + 
		N'     ELSE ''Other''' + @crlf + 
		N'END,' + @crlf + 
		N'LEFT(physical_name, 1), ' + @crlf + 
		N'CAST(FILEPROPERTY ([name], ''SpaceUsed'')/128.0 as decimal(10,2)),' + @crlf + 
		N'CAST([size]/128.0 as decimal(10,2))' + @crlf + 
		N'FROM sys.database_files WITH (NOLOCK)' + @crlf + 
		N'WHERE      [state] = 0' + @crlf + 
		N'AND        [type] IN (0,1)'

		-- Preliminary results
		INSERT DB_FILE_SIZE
		(dbname, file_name, file_type, drive, use_data, total_data_size)
		EXEC (@cmd)


		SET   @counter = @counter - 1
END


/*

ALTER TABLE #Results
ALTER COLUMN TotalDataSize decimal(10,2)

ALTER TABLE #Results
ALTER COLUMN UsedData decimal(10,2)
*/

UPDATE	DB_FILE_SIZE
SET		Smallest = use_data / @target

-- Command determines free space in MB
INSERT INTO @DiskInfo
EXEC master..xp_fixeddrives

---- Final Query
SELECT	DBName,
		file_name,
		file_type,
		r.drive,
		use_data,
		total_data_size - use_data N'FreeData',
		total_data_size,
		CAST(((total_data_size - use_data) / total_data_size) * 100 as decimal(5,2)) [%DataFeeSpace],
		d.MBFree N'DiskFreeSpace',
		Smallest N'SmallestForTarget' ,
		CASE
			  WHEN total_data_size > Smallest THEN CAST(total_data_size - Smallest as varchar(10)) + N' Decrease'
			  ELSE CAST(Smallest - total_data_size as varchar(10)) + N' Increase'
		END N'CandidateResult',
		CASE 
			WHEN Smallest - total_data_size > d.MBFree THEN N'Insufficient Disk Space'
			  WHEN total_data_size > Smallest 
					THEN N'USE [' + dbname + N'] DBCC SHRINKFILE(' + QUOTENAME([file_name], '''') + N', ' + CAST(CAST(Smallest as int) as varchar(10)) + N')'
			  ELSE  N'ALTER DATABASE [' + dbname + N']' + @crlf + 
						  N'MODIFY FILE (' + @crlf + 
						  N'     NAME = ' + [file_name] + N',' + @crlf + 
						  N'     SIZE = ' + CAST(CAST(Smallest as int) as varchar(10)) + @crlf + 
						  N'     )' 
		END N'CandidateCommand'
FROM	DB_FILE_SIZE r 
JOIN	@DiskInfo d
ON		r.Drive = d.Drive
ORDER BY dbname, file_type, r.Drive,(total_data_size - use_data) / total_data_size


-- 용량 사이즈 update
update  SERVER_DISK
    set freesize = d.MBFree
from SERVER_DISK  as s inner join @DiskInfo  as d on s.drv_letter = d.Drive



RETURN


SET QUOTED_IDENTIFIER ON 

