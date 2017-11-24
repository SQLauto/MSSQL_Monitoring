
/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: REINDEX 진행
. 실행예제    
  - exec UP_DBA_TARGET_LIST_REINDEX 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
	   2015-11-04					 최보라		  자동 REINDEX 대상만 , MOD 1일 경우 큰 테이블만 진행 함.
	   2014-11-06					 최보라		  INDEX 번호를 잘 못 가져오는 버그 수정
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_TARGET_LIST_REINDEX
	 @MOD		INT  = NULL

AS
BEGIN
	set nocount on 


	IF @MOD IS NULL SET @MOD =99
	
	waitfor delay '00:00:01'
	--1. pick any index which is not performed currently
	DECLARE @TARGET_SEQ bigint
	DECLARE @DB_NAME varchar(30)
	DECLARE @TABLE_NAME varchar(100)
	DECLARE @INDEX_NAME varchar(300)
	DECLARE @EXEC_SCRIPT nvarchar(4000)
	DECLARE @INDEX_SEQ INT

	--동일 테이블 제외, 동일 DB는 MAX 2개까지
	
	SELECT TOP 1 @TARGET_SEQ=TARGET_SEQ, @DB_NAME = DB_NAME, @TABLE_NAME = TABLE_NAME, @INDEX_NAME = INDEX_NAME, @EXEC_SCRIPT = EXEC_SCRIPT, @INDEX_SEQ= INDEX_SEQ
		FROM DBA_REINDEX_TARGET_LIST 
		WHERE TABLE_NAME NOT IN (SELECT TABLE_NAME FROM DBA_REINDEX_MOD_META)
			AND DB_NAME NOT IN (SELECT DB_NAME FROM 
							(
								SELECT DB_NAME AS DB_NAME, COUNT(*) AS COUNT FROM DBA_REINDEX_MOD_META GROUP BY DB_NAME
							) AS A WHERE COUNT > 2
				)
			AND EXEC_END_DT IS NULL
			AND AUTO_YN = 'Y'  -- 자동 실행 하는 것만 진행
			AND ISNULL(MOD,99) = (  CASE WHEN @MOD  = 1 THEN @MOD ELSE 99 END ) 
		ORDER BY TARGET_SEQ 

	--SELECT @TARGET_SEQ,@DB_NAME,@TABLE_NAME,@INDEX_NAME,@EXEC_SCRIPT, @INDEX_SEQ

	IF @TARGET_SEQ IS NULL
	BEGIN
		return;
	END

	--2. INSERT INTO META TABLE (TABLE EXECUTION IS OCCUPIED
	INSERT INTO DBA_REINDEX_MOD_META (TARGET_SEQ,DB_NAME,TABLE_NAME,INDEX_NAME)
	VALUES(@TARGET_SEQ,@DB_NAME,@TABLE_NAME,@INDEX_NAME)

	--3. PERFORM REINDEX
	UPDATE DBA_REINDEX_TARGET_LIST
		SET EXEC_START_DT = GETDATE()
	WHERE TARGET_SEQ = @TARGET_SEQ
	
	DECLARE @SQL nvarchar(4000)
	SET @SQL = N'SET QUERY_GOVERNOR_COST_LIMIT 0'+char(10)+@EXEC_SCRIPT

	--EXEC SP_EXECUTESQL @SQL
	--print @sql 

	begin try
		EXEC SP_EXECUTESQL @SQL
	end try
	begin catch

		UPDATE DBA_REINDEX_TARGET_LIST SET EXEC_END_DT = GETDATE(), PERCENTAGE = -1 WHERE DBA_REINDEX_TARGET_LIST.TARGET_SEQ = @TARGET_SEQ
		
		DELETE FROM DBA_REINDEX_MOD_META WHERE TARGET_SEQ = @TARGET_SEQ
		
		drop table #T
		drop table #T1
		return;
	end catch;


	--4. GATHER INDEX INFO AFTER REINDEX

	DECLARE @INDEX_ID INT
	DECLARE @SCHEMA_NAME VARCHAR(50)

	SELECT TOP 1 @INDEX_ID=INDEX_ID,@SCHEMA_NAME=SCHEMA_NAME
	from DBA_REINDEX_TOTAL_LIST WITH(NOLOCK)
	--WHERE DB_NAME = @DB_NAME AND TABLE_NAME =@TABLE_NAME AND INDEX_NAME =@INDEX_NAME
	WHERE INDEX_SEQ = @INDEX_SEQ AND DB_NAME = @DB_NAME AND TABLE_NAME = @TABLE_NAME AND INDEX_NAME = @INDEX_NAME

	DECLARE @FULL_TABLE varchar(150)
	SET @FULL_TABLE = @DB_NAME+'.'+@SCHEMA_NAME+'.'+@TABLE_NAME

	SELECT * INTO #T
	FROM sys.dm_db_index_physical_stats(DB_ID(@DB_NAME), OBJECT_ID(@FULL_TABLE), @INDEX_ID, NULL, 'DETAILED')

	DECLARE @INDEX_SIZE bigint 

	SET @EXEC_SCRIPT = '
	select SUM(B.used_page_count) * 8 
			from '+@DB_NAME+'.sys.dm_db_partition_stats B WITH(NOLOCK) 
			WHERE OBJECT_ID = OBJECT_ID('''+@FULL_TABLE+''') and INDEX_ID = '+CONVERT(VARCHAR(5),@INDEX_ID)+'
	'

	CREATE TABLE #T1
	(
		size bigint
	)

	insert into #T1
	EXEC SP_EXECUTESQL @EXEC_SCRIPT

	SELECT @INDEX_SIZE = size FROM #T1 with(nolock)

	--5. UPDATE TARGET LIST
	UPDATE DBA_REINDEX_TARGET_LIST
	SET
	CURRENT_AVG_FRAGMENTATION_IN_PERCENT = B.AVG_FRAGMENTATION_IN_PERCENT
	,CURRENT_FRAGMENT_COUNT = B.FRAGMENT_COUNT
	,CURRENT_AVG_FRAGMENT_SIZE_IN_PAGES =B.AVG_FRAGMENT_SIZE_IN_PAGES
	,CURRENT_PAGE_COUNT = B.PAGE_COUNT
	,CURRENT_AVG_PAGE_SPACE_USED_IN_PERCENT = B.AVG_PAGE_SPACE_USED_IN_PERCENT
	,CURRENT_RECORD_COUNT = B.RECORD_COUNT
	,CURRENT_INDEX_SIZE_KB = @INDEX_SIZE
	,EXEC_END_DT = GETDATE()
	,PERCENTAGE =100
	FROM (
			select top 1 * from #T ORDER BY record_count desc
		) B
	WHERE DBA_REINDEX_TARGET_LIST.TARGET_SEQ = @TARGET_SEQ

	DELETE FROM DBA_REINDEX_MOD_META WHERE TARGET_SEQ = @TARGET_SEQ

	drop table #T
	drop table #T1


	-- Log Size Check




END


