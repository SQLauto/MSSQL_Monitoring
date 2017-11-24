/*****************************************************************************************************************   
. 작 성 자: 최보라   
. 작 성 일: 2015-11-04   
. 유지보수: 최보라
. 기능구분: REINDEX 대상 조정
. 실행예제    
  - exec UP_DBA_TARGET_LIST_REINDEX_UPDATE
*****************************************************************************************************************   
변경내역:   
        수정일자        수정구분        수정자        수정내용   
==========================================================================   

*****************************************************************************************************************/   
CREATE PROCEDURE dbo.UP_DBA_TARGET_LIST_REINDEX_UPDATE
	@RANK		INT, 
	@SIZE 		INT

AS
BEGIN
	set nocount on 
	-- INDEX_SIZE >= 300GB 이상은 자동으로 처리 하지 않음 
	UPDATE DBA_REINDEX_TARGET_LIST SET AUTO_YN = 'N'  WHERE PAST_INDEX_SIZE_KB >= @SIZE	 * 1024 *1024  AND EXEC_END_DT IS NULL
	
	
	
	UPDATE  B
	SET MOD = 1 
	FROM 
		(	SELECT RANK() OVER  ( ORDER BY PAST_INDEX_SIZE_KB DESC ) AS RNK, TARGET_SEQ 
			FROM  DBA_REINDEX_TARGET_LIST  WITH(NOLOCK) 
			WHERE EXEC_END_DT IS NULL
			AND AUTO_YN='Y'
		) AS A
		JOIN DBA_REINDEX_TARGET_LIST AS B WITH(NOLOCK) ON A.TARGET_SEQ = B.TARGET_SEQ
	WHERE A.RNK <= @RANK
END
GO
