/*****************************************************************************************************************   
.   :    
.   : 2015-02-02   
. : GmarketDBA    
. : DB  Index      
.     
  - exec UP_DBA_COLLECT_REINDEX_INFO_TARGET 
*****************************************************************************************************************   
:   
                                   
==========================================================================   
       2015-02-02   
       2015-06-03 by choi bo ra unused index 사이즈 변경량                          
*****************************************************************************************************************/   
ALTER PROCEDURE dbo.UP_DBA_COLLECT_REINDEX_INFO_TARGET
	@minRowCount int = 1000 --  Row 
	,@minDelCount int = 100 -- trans_basic_master  del_count  
	,@retentionRowPercentage int = 2 -- row /  row 
	,@updatePercentage int = 2 --  row / update  
	,@lookupPercentage int = 2 --  row / lookup 
	,@indexSizeRatio int = 2 -- index   
AS
BEGIN
	SET NOCOUNT ON

	--DECLARE @minRowCount int --  Row 
	--DECLARE @minDelCount int -- trans_basic_master  del_count  
	--DECLARE @retentionRowPercentage int -- row /  row 
	--DECLARE @updatePercentage int --  row / update  
	--DECLARE @lookupPercentage int --  row / lookup 
	--DECLARE @indexSizeRatio int -- index   

	--SET @minRowCount = 3000000
	--SET @minDelCount = 1000
	--SET @retentionRowPercentage = 10
	--SET @updatePercentage = 5
	--SET @lookupPercentage = 2
	--SET @indexSizeRatio = 2



	/*
	*IFF: The Length of DBA..DBA_REINDEX_INFO_LOG's unexecuted log entries > 30 
	*/

	DECLARE @unexecCnt int
	SELECT @unexecCnt = COUNT(*) FROM DBA..DBA_REINDEX_INFO_LOG WITH(NOLOCK) WHERE EXEC_END_DT IS NULL

	IF (@unexecCnt > 30)
	BEGIN
		PRINT 'The count of unexecuted entries are more than 30.'
		RETURN;
	END

	/*
	*IFF: TABLE Bigger than 1,000,000 rows & Retention with more than 1,000 delete per each & Deleted row (5days) / Total row > 10%
	*/

	SELECT A.*, B.DEL_COUNT AS DEL_COUNT, 0 AS DEL_ROW_COUNT
	INTO #T
		FROM DBA..DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK) 
		INNER JOIN DBA..TRANS_BASIC_MASTER B WITH(NOLOCK) ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME = B.TABLE_NAME
		--INNER JOIN DBA..TRANS_BASIC_MASTER_LOG C WITH(NOLOCK) ON A.DB_NAME = C.DB_NAME AND A.TABLE_NAME = C.TABLE_NAME
	WHERE A.ROW_COUNT >= @minRowCount AND B.DEL_COUNT >= @minDelCount

	
	--WHEN THE REINDEX HAPPEND WITHIN A MONTH, EXCLUDE.
	DELETE FROM #T 
	WHERE INDEX_SEQ IN(
		SELECT DISTINCT INDEX_SEQ FROM DBA..DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
		WHERE REG_DT > DATEADD(day,-20,getdate())
	)

	--Gather information of total deleted row counts in 5days
	UPDATE A
	SET A.DEL_ROW_COUNT =  B.DEL_ROW_COUNT
		FROM #T A WITH(NOLOCK)
		INNER JOIN (
			select A.DB_NAME, A.TABLE_NAME, SUM(B.ROW_COUNT) AS DEL_ROW_COUNT
				FROM #T A WITH(NOLOCK)
				INNER JOIN DBA..TRANS_BASIC_MASTER_LOG B WITH(NOLOCK) ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME = B.TABLE_NAME
				WHERE START_TIME > GETDATE()-5
				GROUP BY A.DB_NAME, A.TABLE_NAME
		) AS B ON A.DB_NAME = B.DB_NAME AND A.TABLE_NAME=B.TABLE_NAME
	
	--insert into targets when the ratio of total row counts and deleted row counts hits the certain level
	INSERT INTO DBA..DBA_REINDEX_INFO_LOG (INDEX_SEQ)
	SELECT DISTINCT INDEX_SEQ FROM #T WITH(NOLOCK) 
		WHERE ((DEL_ROW_COUNT * 1.0)/ROW_COUNT) * 100 > @retentionRowPercentage

	DROP TABLE #T

-- OR 조건. 

	/*
	* Accum of 5days of updates or lookups from INDEX_USAGE >  5% or 2% of total row count
	*/

	INSERT INTO DBA..DBA_REINDEX_INFO_LOG (INDEX_SEQ)
	SELECT distinct INDEX_SEQ
		FROM 
	(
		SELECT  B.INDEX_SEQ, B.ROW_COUNT, AVG(user_updates)+ AVG(system_updates) as UPDATE_COUNT, AVG(user_lookups)+AVG(system_lookups) as LOOKUP_COUNT
		, MAX(C.EXEC_START_DT) as EXEC_START_DT
			FROM INDEX_USAGE A with(nolock) 
			INNER JOIN DBA..DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON A.OBJECT_ID = B.OBJECT_ID AND A.index_id = B.INDEX_ID
			INNER JOIN DBA..DBA_REINDEX_INFO_LOG C WITH(NOLOCK) ON B.INDEX_SEQ = C.INDEX_SEQ
		WHERE A.reg_date > getdate()-5 AND B.ROW_COUNT >= @minRowCount 
		GROUP BY B.INDEX_SEQ, A.database_name, A.object_name, A.index_name, B.ROW_COUNT	
	) AS A
	WHERE (EXEC_START_DT IS NULL OR EXEC_START_DT < GETDATE()-20)
	AND (((UPDATE_COUNT*1.0) / ROW_COUNT)*100 > @updatePercentage OR ((LOOKUP_COUNT*1.0) / ROW_COUNT)*100 > @lookupPercentage)
	AND INDEX_SEQ NOT IN(
		SELECT DISTINCT INDEX_SEQ FROM DBA..DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
		WHERE REG_DT > DATEADD(day,-20,getdate()
	    )
	)

	/*
	* Changes on current INDEX_SIZE 2 time larger than recorded INDEX_SIZE
	*/

	CREATE TABLE #T1
	(
		db_name		sysname,
		OBJECT_ID	bigint,
		INDEX_ID	bigint,
		ROW_COUNT	bigint,
		INDEX_SIZE_KB bigint, 
		UNUSED_INDEX_SIZE_KB BIGINT,
	)

	--collect index size info over all databases
	INSERT INTO #T1
	EXEC sp_MSforeachdb N'
		USE [?];
		select db_name(),object_id, index_id, row_count, SUM(B.used_page_count) * 8  AS INDEX_SIZE_KB, SUM(RESERVED_PAGE_COUNT-USED_PAGE_COUNT) * 8 AS UNSUED_INDEX_SIZE_KB
		from sys.dm_db_partition_stats B WITH(NOLOCK) 
		WHERE row_count > 1000 and B.used_page_count > 0 
		group by object_id, index_id, row_count'

	--insert into reindex table when the ratio of index_size / row_count hits certain level
	INSERT INTO DBA..DBA_REINDEX_INFO_LOG (INDEX_SEQ)
	SELECT distinct INDEX_SEQ 
	FROM(
			SELECT distinct  A.INDEX_SEQ, A.INDEX_SIZE_KB as INDEX_SIZE_KB_BEFORE, B.INDEX_SIZE_KB as INDEX_SIZE_KB_AFTER,  B.UNUSED_INDEX_SIZE_KB  AS UNUSED_INDEX_SIZE_KB_AFTER,
				A.ROW_COUNT as ROW_COUNT_BEFORE, B.ROW_COUNT as ROW_COUNT_AFTER, MAX(C.EXEC_START_DT) as EXEC_START_DT, A.UNUSED_INDEX_SIZE_KB AS  UNUSED_INDEX_SIZE_KB_BEFORE
			FROM DBA..DBA_REINDEX_TOTAL_LIST A WITH(NOLOCK)
				INNER JOIN #T1 B WITH(NOLOCK) ON A.DB_NAME = B.db_name and A.OBJECT_ID =B.OBJECT_ID  and A.INDEX_ID = B.INDEX_ID
				LEFT JOIN DBA..DBA_REINDEX_INFO_LOG C WITH(NOLOCK) ON A.INDEX_SEQ = C.INDEX_SEQ
			GROUP BY A.INDEX_SEQ, A.INDEX_SIZE_KB, A.ROW_COUNT,A.INDEX_SIZE_KB, B.INDEX_SIZE_KB, A.ROW_COUNT, B.ROW_COUNT, B.UNUSED_INDEX_SIZE_KB, A.UNUSED_INDEX_SIZE_KB
			) A
WHERE INDEX_SIZE_KB_BEFORE >0 and ROW_COUNT_BEFORE>0   AND UNUSED_INDEX_SIZE_KB_BEFORE >0 
	AND (  (INDEX_SIZE_KB_AFTER*1.0 / INDEX_SIZE_KB_BEFORE) / (ROW_COUNT_AFTER*1.0 / ROW_COUNT_BEFORE) > @indexSizeRatio 
		  OR 
		  	 (UNUSED_INDEX_SIZE_KB_AFTER*1.0 / UNUSED_INDEX_SIZE_KB_BEFORE) > @indexSizeRatio
		  	
		  ) 
	AND (EXEC_START_DT IS NULL OR EXEC_START_DT < GETDATE()-20)
	AND INDEX_SEQ NOT IN(
		SELECT DISTINCT INDEX_SEQ FROM DBA..DBA_REINDEX_INFO_LOG WITH(NOLOCK) 
		WHERE REG_DT > DATEADD(day,-20,getdate())
	)

	drop table #T1
END

