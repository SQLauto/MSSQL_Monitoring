-- gmarket 

/*****************************************************************************************************************   
. 작 성 자: 전세환   
. 작 성 일: 2015-02-02   
. 유지보수: GmarketDBA팀 전세환   
. 기능구분: DB 전체 Index 정보 기반으로 단편화 조회 대상 추출
. 실행예제    
  - exec UP_DBA_COLLECT_REINDEX_TARGET_LIST 
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   
       2015-02-02                    전세환        신규생성 
*****************************************************************************************************************/   
CREATE PROCEDURE dbo.UP_DBA_COLLECT_REINDEX_TARGET_LIST
	@PAD_INDEX varchar(3) = 'OFF'
	,@FILLFACTOR int = 90
	,@SORT_IN_TEMPDB varchar(3) = 'OFF'
	,@IGNORE_DUP_KEY varchar(3) = 'OFF'
	,@STATISTICS_NORECOMPUTE varchar(3) = 'OFF'
	,@ONLINE varchar(3) = 'ON'
	,@ALLOW_ROW_LOCKS varchar(3) = 'ON'
	,@ALLOW_PAGE_LOCKS varchar(3) = 'ON'
	,@MAXDOP int = 8
	,@DATA_COMPRESSION varchar(10) = 'PAGE'

AS
BEGIN
	SET NOCOUNT ON
/*
declare @PAD_INDEX varchar(3)
declare @FILLFACTOR int
declare @SORT_IN_TEMPDB varchar(3)
declare @IGNORE_DUP_KEY varchar(3)
declare @STATISTICS_NORECOMPUTE varchar(3)
declare @ONLINE varchar(3)
declare @ALLOW_ROW_LOCKS varchar(3)
declare @ALLOW_PAGE_LOCKS varchar(3)
declare @MAXDOP int
declare @DATA_COMPRESSION varchar(10)

SET @PAD_INDEX = 'OFF'
SET @FILLFACTOR = 90
SET @SORT_IN_TEMPDB = 'OFF'
SET @IGNORE_DUP_KEY = 'OFF'
SET @STATISTICS_NORECOMPUTE = 'OFF'
SET @ONLINE = 'ON'
SET @ALLOW_ROW_LOCKS = 'ON'
SET @ALLOW_PAGE_LOCKS = 'ON'
SET @MAXDOP = 8
SET @DATA_COMPRESSION = 'PAGE'
*/

INSERT INTO DBA_REINDEX_TARGET_LIST
(
DB_NAME
,TABLE_NAME
,INDEX_NAME
,INDEX_SEQ
,LOG_SEQ
,EXEC_SCRIPT
,PAST_AVG_FRAGMENTATION_IN_PERCENT
,PAST_FRAGMENT_COUNT
,PAST_AVG_FRAGMENT_SIZE_IN_PAGES
,PAST_PAGE_COUNT
,PAST_AVG_PAGE_SPACE_USED_IN_PERCENT
,PAST_RECORD_COUNT
,PAST_INDEX_SIZE_KB
,REG_DT
)
select  B.DB_NAME, B.TABLE_NAME, B.INDEX_NAME, B.INDEX_SEQ, A.LOG_SEQ, '
USE ' + B.DB_NAME +';

ALTER INDEX '+ B.INDEX_NAME +' ON '+ B.TABLE_NAME +'
REBUILD WITH( PAD_INDEX = '+@PAD_INDEX+', FILLFACTOR = '+CONVERT(varchar(3),@FILLFACTOR)+', SORT_IN_TEMPDB = '+@SORT_IN_TEMPDB+
	'--, IGNORE_DUP_KEY = '+@IGNORE_DUP_KEY+char(10)+', STATISTICS_NORECOMPUTE = '+@STATISTICS_NORECOMPUTE+',ONLINE = '+@ONLINE+
	', ALLOW_ROW_LOCKS = '+@ALLOW_ROW_LOCKS+', ALLOW_PAGE_LOCKS = '+@ALLOW_PAGE_LOCKS+
	', MAXDOP = '+CONVERT(varchar(3),@MAXDOP)+', DATA_COMPRESSION = '+@DATA_COMPRESSION+')'
,AVG_FRAGMENTATION_IN_PERCENT,FRAGMENT_COUNT
,AVG_FRAGMENT_SIZE_IN_PAGES,PAGE_COUNT,AVG_PAGE_SPACE_USED_IN_PERCENT,RECORD_COUNT,INDEX_SIZE_KB, GETDATE()
from DBA_REINDEX_INFO_LOG A WITH(NOLOCK)
	INNER JOIN DBA_REINDEX_TOTAL_LIST B with(nolock) ON A.INDEX_SEQ = B.INDEX_SEQ
	LEFT JOIN DBA_REINDEX_TARGET_LIST AS T WITH(NOLOCK) ON A.INDEX_SEQ = T.INDEX_SEQ  AND T.EXEC_END_DT IS NULL
WHERE 
	--A.LOG_SEQ NOT IN (SELECT LOG_SEQ FROM DBA_REINDEX_TARGET_LIST  WITH(NOLOCK) WHERE EXEC_END_DT IS NOT NULL )
	(A.AVG_FRAGMENTATION_IN_PERCENT > 40 or A.AVG_PAGE_SPACE_USED_IN_PERCENT < 60)
	AND T.INDEX_SEQ IS NULL
	AND A.EXEC_END_DT >= DATEADD(DD,-7, CONVERT(NVARCHAR(10), GETDATE(), 121) ) AND 
	  A.EXEC_END_DT < DATEADD(DD,1, CONVERT(NVARCHAR(10), GETDATE(), 121) ) 
		
ORDER BY TABLE_NAME
END

