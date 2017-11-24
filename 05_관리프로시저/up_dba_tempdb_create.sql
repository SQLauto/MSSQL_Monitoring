
/*************************************************************************  
* 프로시저명  : dbo.up_dba_tempdb_create
* 작성정보    : 2015-12-15 by choi bo ra
* 관련페이지  : 
* 내용        : tempdb 생성
* 수정정보    : 
EXEC [up_dba_tempdb_create] 8, 102400, 'M:\TEMPDB'
**************************************************************************/
CREATE PROCEDURE [dbo].[up_dba_tempdb_create]
	@NEW_DATA_FILE_CNT INT, 
	@NEW_FILE_SIZE	   INT = NULL, 
	@NEW_FILE_DIR  SYSNAME = NULL, 
	@IS_SINGLE		CHAR(1)  = 'Y'
AS
/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE */
declare @TOT_DATA_FILE_CNT INT, @I INT, @NAME SYSNAME, @TOT_SIZE_MB INT, @SIZE_MB INT
DECLARE @SQL NVARCHAR(MAX), @NEW_I INT

/* BODY */
SET @I =2
SET @SQL =''

SELECT IDENTITY(INT,1,1) AS SEQ,  NAME , SIZE
	INTO #TMP_TEMPDB_FILE
FROM TEMPDB.DBO.SYSFILES 
 WHERE GROUPID = 1
ORDER BY FILEID


SELECT  @TOT_DATA_FILE_CNT= COUNT(*), @TOT_SIZE_MB = SUM(SIZE /128)  
FROM #TMP_TEMPDB_FILE



IF @NEW_DATA_FILE_CNT <= @TOT_DATA_FILE_CNT
BEGIN

	--Size를 조정을 먼저 처리 한다. 줄이는 작업이 잘 되지 않음 으로 

			print '/***************************************************************************************'
			print '-- SQL 을 최소모드,단일 사용자로 접속 해야 한다.'
			print '-- 그래야 축소가 쉽게 된다. '
			print '방법 1) sqlservr.exe 실행은 SQL이 설치된 폴더의 bin 에서 실행 해야 한다. '
		  print '--클러스터 관리자에서 정상적으로 종료'
			print '--sqlservr.exe -m'
			print '--실행한 도스 명령창 죽이지 않고 그대로 둔다. '
		  print '-- 객체 탐색기 포함해서 모든 세션은 연결 끊어야 함.'
			print '--SSMS 에서 DAC 세션으로 접속 한다. (데이터베이스 엔진 쿼리)'
			print '--tempdb 조정 작업 -> 실행중인 도스창 중지-> 정상적으로 SQL 다시 시작 '
			print ''
			print '	방법 2) '
		   print '--클러스터 관리자에서 정상적으로 종료'
			print '--명령 창에서 net start MSSQLSERVER /m 시작'
			print '--SSMS 에서 DAC 세션으로 접속 한다. (데이터베이스 엔진 쿼리)'
			print '-- 객체 탐색기 포함해서 모든 세션은 연결 끊어야 함.'
			print '--tempdb 조정 작업 ->정상적으로 SQL 다시 시작 (클러스터 관리자에서 실행 ) '		
			print '****************************************************************************************/'
	

	SELECT 'TEMPDB DATA FILE 수 : ' + CONVERT(NVARCHAR(3), @TOT_DATA_FILE_CNT) + ' ->  ' +  CONVERT(NVARCHAR(3), @NEW_DATA_FILE_CNT)  + ' 감소 작업'

	IF @NEW_FILE_SIZE IS NULL
		SELECT @SIZE_MB = @TOT_SIZE_MB / @NEW_DATA_FILE_CNT 
	ELSE 
		SELECT @SIZE_MB = @NEW_FILE_SIZE / @NEW_DATA_FILE_CNT 

	IF @IS_SINGLE = 'Y' -- 싱글유저 실행
	BEGIN

			
		-- 파일 조정 
		SET @SQL = ''
		SET @SQL = 'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = ''TEMPDEV'', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB ) + 'MB , FILEGROWTH =0 ) ' + CHAR(10)


		
		SET @I =2
		WHILE ( @I <=@NEW_DATA_FILE_CNT )
		BEGIN

			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @I


			SET @SQL += 'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = TEMPDB_DATA'  + CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END 
						 + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB )  + 'MB, FILENAME = '''  + @NEW_FILE_DIR + '\TEMPDB_DATA' +  CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END
						 + '.NDF'', FILEGROWTH =0 ) ' + CHAR(10)



			SET @I =@I + 1
		END

		PRINT @SQL

		--  넘어가는 숫자는  LDF 부터 지운다.
		SET @SQL = 'USE TEMPDB' + CHAR(10) + 'GO' + CHAR(10)
		SET @NEW_I = @I 

		WHILE (@NEW_I  <= @TOT_DATA_FILE_CNT ) 
		BEGIN
			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @NEW_I

			SET @SQL += 'DBCC SHRINKFILE(NAME =' + @NAME + ', EMPTYFILE) ' + CHAR(10)
					   + 'ALTER DATABASE TEMPDB REMOVE FILE  ' + @NAME + CHAR(10)


			SET @NEW_I =@NEW_I + 1
		END

		PRINT @SQL





	END
	ELSE
	BEGIN

		-- 파일 조정 
		SET @SQL = ''
		SET @SQL = 'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = ''TEMPDEV'', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB ) + 'MB , FILEGROWTH =0 ) ' + CHAR(10)


		SET @I =2
		WHILE ( @I <=@NEW_DATA_FILE_CNT )
		BEGIN

			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @I
			SET @SQL = @SQL + 'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = ' + @NAME + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB ) + 'MB , FILEGROWTH =0 ) ' + CHAR(10)
		
			SET @I =@I + 1
		END

		PRINT @SQL


		--  넘어가는 숫자는  LDF 부터 지운다.
		SET @SQL = 'USE TEMPDB' + CHAR(10) + 'GO' + CHAR(10)
		SET @NEW_I = @I 

		WHILE (@NEW_I  <= @TOT_DATA_FILE_CNT ) 
		BEGIN
			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @NEW_I

			SET @SQL += 'DBCC SHRINKFILE(NAME =' + @NAME + ', EMPTYFILE) ' + CHAR(10)
					   + 'ALTER DATABASE TEMPDB REMOVE FILE  ' + @NAME + CHAR(10)


			SET @NEW_I =@NEW_I + 1
		END

		PRINT @SQL

	END

END
ELSE -- 추가 
BEGIN


		SELECT 'TEMPDB DATA FILE 수 : ' + CONVERT(NVARCHAR(3), @TOT_DATA_FILE_CNT) + ' ->  ' +  CONVERT(NVARCHAR(3), @NEW_DATA_FILE_CNT)  + ' 추가 작업'
		--SELECT  @SIZE_MB= MAX(SIZE /128)  FROM TEMPDB.DBO.SYSFILES  WHERE GROUPID = 1

		IF @NEW_FILE_SIZE IS NULL
			SELECT @SIZE_MB = @TOT_SIZE_MB / @NEW_DATA_FILE_CNT 
		ELSE 
			SELECT @SIZE_MB = @NEW_FILE_SIZE / @NEW_DATA_FILE_CNT 

		
		SET @I =1
		WHILE (@I  <= @TOT_DATA_FILE_CNT)  -- 있는 것 LOOP 
		BEGIN

			

			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @I
			SET @SQL = @SQL +  'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = ' + @NAME + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB ) + 'MB,  FILEGROWTH =0  )' + CHAR(10)
			
			SET @I =@I + 1

		END


			PRINT @SQL
	
	
		SET @SQL = ''
		WHILE (@I  <= @NEW_DATA_FILE_CNT)  -- 있는 것 LOOP 
		BEGIN

		
			
			SET @SQL += 'ALTER DATABASE TEMPDB ADD FILE  ( NAME = TEMPDB_DATA'  + CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END 
						 + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB )  + 'MB, FILENAME = '''  + @NEW_FILE_DIR + '\TEMPDB_DATA' +  CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END
						 + '.NDF'', FILEGROWTH =0 ) ' + CHAR(10)


			SET @I =@I + 1
		END


			PRINT @SQL
	
END
go