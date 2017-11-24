
/*************************************************************************  
* ���ν�����  : dbo.up_dba_tempdb_create
* �ۼ�����    : 2015-12-15 by choi bo ra
* ����������  : 
* ����        : tempdb ����
* ��������    : 
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

	--Size�� ������ ���� ó�� �Ѵ�. ���̴� �۾��� �� ���� ���� ���� 

			print '/***************************************************************************************'
			print '-- SQL �� �ּҸ��,���� ����ڷ� ���� �ؾ� �Ѵ�.'
			print '-- �׷��� ��Ұ� ���� �ȴ�. '
			print '��� 1) sqlservr.exe ������ SQL�� ��ġ�� ������ bin ���� ���� �ؾ� �Ѵ�. '
		  print '--Ŭ������ �����ڿ��� ���������� ����'
			print '--sqlservr.exe -m'
			print '--������ ���� ���â ������ �ʰ� �״�� �д�. '
		  print '-- ��ü Ž���� �����ؼ� ��� ������ ���� ����� ��.'
			print '--SSMS ���� DAC �������� ���� �Ѵ�. (�����ͺ��̽� ���� ����)'
			print '--tempdb ���� �۾� -> �������� ����â ����-> ���������� SQL �ٽ� ���� '
			print ''
			print '	��� 2) '
		   print '--Ŭ������ �����ڿ��� ���������� ����'
			print '--��� â���� net start MSSQLSERVER /m ����'
			print '--SSMS ���� DAC �������� ���� �Ѵ�. (�����ͺ��̽� ���� ����)'
			print '-- ��ü Ž���� �����ؼ� ��� ������ ���� ����� ��.'
			print '--tempdb ���� �۾� ->���������� SQL �ٽ� ���� (Ŭ������ �����ڿ��� ���� ) '		
			print '****************************************************************************************/'
	

	SELECT 'TEMPDB DATA FILE �� : ' + CONVERT(NVARCHAR(3), @TOT_DATA_FILE_CNT) + ' ->  ' +  CONVERT(NVARCHAR(3), @NEW_DATA_FILE_CNT)  + ' ���� �۾�'

	IF @NEW_FILE_SIZE IS NULL
		SELECT @SIZE_MB = @TOT_SIZE_MB / @NEW_DATA_FILE_CNT 
	ELSE 
		SELECT @SIZE_MB = @NEW_FILE_SIZE / @NEW_DATA_FILE_CNT 

	IF @IS_SINGLE = 'Y' -- �̱����� ����
	BEGIN

			
		-- ���� ���� 
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

		--  �Ѿ�� ���ڴ�  LDF ���� �����.
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

		-- ���� ���� 
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


		--  �Ѿ�� ���ڴ�  LDF ���� �����.
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
ELSE -- �߰� 
BEGIN


		SELECT 'TEMPDB DATA FILE �� : ' + CONVERT(NVARCHAR(3), @TOT_DATA_FILE_CNT) + ' ->  ' +  CONVERT(NVARCHAR(3), @NEW_DATA_FILE_CNT)  + ' �߰� �۾�'
		--SELECT  @SIZE_MB= MAX(SIZE /128)  FROM TEMPDB.DBO.SYSFILES  WHERE GROUPID = 1

		IF @NEW_FILE_SIZE IS NULL
			SELECT @SIZE_MB = @TOT_SIZE_MB / @NEW_DATA_FILE_CNT 
		ELSE 
			SELECT @SIZE_MB = @NEW_FILE_SIZE / @NEW_DATA_FILE_CNT 

		
		SET @I =1
		WHILE (@I  <= @TOT_DATA_FILE_CNT)  -- �ִ� �� LOOP 
		BEGIN

			

			SELECT @NAME = NAME FROM #TMP_TEMPDB_FILE WHERE SEQ = @I
			SET @SQL = @SQL +  'ALTER DATABASE TEMPDB MODIFY FILE  ( NAME = ' + @NAME + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB ) + 'MB,  FILEGROWTH =0  )' + CHAR(10)
			
			SET @I =@I + 1

		END


			PRINT @SQL
	
	
		SET @SQL = ''
		WHILE (@I  <= @NEW_DATA_FILE_CNT)  -- �ִ� �� LOOP 
		BEGIN

		
			
			SET @SQL += 'ALTER DATABASE TEMPDB ADD FILE  ( NAME = TEMPDB_DATA'  + CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END 
						 + ', SIZE = ' + CONVERT(NVARCHAR(10),@SIZE_MB )  + 'MB, FILENAME = '''  + @NEW_FILE_DIR + '\TEMPDB_DATA' +  CASE WHEN LEN(@I) < 2 THEN '0' + CONVERT(NVARCHAR(2), @I) ELSE CONVERT(NVARCHAR(2), @I) END
						 + '.NDF'', FILEGROWTH =0 ) ' + CHAR(10)


			SET @I =@I + 1
		END


			PRINT @SQL
	
END
go