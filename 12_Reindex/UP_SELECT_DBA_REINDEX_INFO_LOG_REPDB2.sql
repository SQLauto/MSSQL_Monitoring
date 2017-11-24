
/*****************************************************************************************************************   
* 프로시저명: DBO.UP_SELECT_DBA_REINDEX_INFO_LOG_
* 작성정보	: 2015-11-20 이예지
* 관련페이지:  
* 내용		: REINDEX REPDB2 결과 가져온 DBA_REINDEX_INFO_LOG_WORK 테이블로 MAINDB2/ITEMDB1 서버 원본 테이블을 UPDATE 

* 수정정보	: EXEC UP_SELECT_DBA_REINDEX_INFO_LOG_  
*****************************************************************************************************************             
*****************************************************************************************************************/   
ALTER PROCEDURE DBO.UP_SELECT_DBA_REINDEX_INFO_LOG
	@server_id int 
AS
BEGIN
	SET NOCOUNT ON
select   
c.INDEX_SEQ
,c.ALLOC_UNIT_TYPE_DESC
,c.INDEX_DEPTH
,c.INDEX_LEVEL
,c.AVG_FRAGMENTATION_IN_PERCENT
,c.FRAGMENT_COUNT
,c.AVG_FRAGMENT_SIZE_IN_PAGES
,c.PAGE_COUNT
,c.AVG_PAGE_SPACE_USED_IN_PERCENT
,c.RECORD_COUNT
,c.GHOST_RECORD_COUNT
,c.VERSION_GHOST_RECORD_COUNT
,c.MIN_RECORD_SIZE_IN_BYTES
,c.MAX_RECORD_SIZE_IN_BYTES
,c.AVG_RECORD_SIZE_IN_BYTES
,c.FORWARDED_RECORD_COUNT
,c.COMPRESSED_PAGE_COUNT
,c.EXEC_START_DT
,c.EXEC_END_DT  
FROM DBA_REINDEX_INFO_LOG C WITH(NOLOCK)
	INNER JOIN DBA_REINDEX_TOTAL_LIST B WITH(NOLOCK) ON C.INDEX_SEQ = B.SYNC_INDEX_SEQ  AND   C.DB_NAME = B.DB_NAME
WHERE C.SERVER_ID = @server_id
END


