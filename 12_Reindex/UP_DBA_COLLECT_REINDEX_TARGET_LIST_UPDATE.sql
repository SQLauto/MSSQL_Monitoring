/*****************************************************************************************************************   
. �� �� ��: �ֺ���   
. �� �� ��: 2015-11-04   
. ��������: �ֺ���
. ��ɱ���: REINDEX ��� ����
. ���࿹��    
  - exec UP_DBA_TARGET_LIST_REINDEX_UPDATE
*****************************************************************************************************************   
���泻��:   
        ��������        ��������        ������        ��������   
==========================================================================   

*****************************************************************************************************************/   
CREATE PROCEDURE dbo.UP_DBA_TARGET_LIST_REINDEX_UPDATE
	@RANK		INT, 
	@SIZE 		INT

AS
BEGIN
	set nocount on 
	-- INDEX_SIZE >= 300GB �̻��� �ڵ����� ó�� ���� ���� 
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
