/*************************************************************************  
* 프로시저명: dbo.up_dba_collect_noused_index_procedure
* 작성정보	: 2015-03-06 by choi bo ra
* 관련페이지:  
* 내용		: 
up_dba_collect_noused_TABLE_procedure
* 수정정보	: 미사용 index를 사용하는 프로시저 찾기
		EXEC dbo.up_dba_collect_noused_index_procedure 'G', 90
		FULLTEXT 엔진으로 인해 계속 찾아도 문제 없음 
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_collect_noused_index_procedure
	@site_gn  CHAR(1) =  'G', 
	@unused_day int  = 90
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @REG_DATE DATE, @SERVER_ID INT, @INDEX_NAME  SYSNAME, @I INT, @SEQ_NO BIGINT
DECLARE @OBJECT_NAME SYSNAME


/*BODY*/

 --SELECT * FROM NOUSED_TARGET_PROCEUDRE_LOG  WHERE REF_TYPE = 'I'  AND SITE_GN = 'G' AND END_TIME IS NULL
-- 수집 기준일 GET
SELECT @REG_DATE = REG_DATE FROM NOUSED_TARGET_INDEX_LOG WITH(NOLOCK)  WHERE SITE_GN = @SITE_GN AND PROCESS_TYPE = 'S'

IF @REG_DATE = CONVERT(DATE, GETDATE())  -- 처음 실행, 기존에 있는것 삭제 하고 다시
BEGIN
	
	DECLARE @TOT_COUNT INT 
	DELETE  I FROM TMP_NOUSED_TARGET_INDEX AS I JOIN SERVERINFO AS S ON I.SERVER_ID =S.SERVER_ID WHERE S.SITE_GN = @SITE_GN
	
	INSERT INTO TMP_NOUSED_TARGET_INDEX
	(SEQNO, SERVER_ID, DATABASE_NAME, OBJECT_NAME, INDEX_ID, INDEX_NAME, SEARCH_YN )
	SELECT DISTINCT I.SEQNO, I.SERVER_ID, I.DATABASE_NAME, I.OBJECT_NAME, I.INDEX_ID, I.INDEX_NAME, 'N' AS SEARCH_YN 
	FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
		JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	WHERE DEL_PROC_TARGET = 'Y'
		AND S.SITE_GN = @SITE_GN
		AND I.UNUSED_DAY >= @unused_day 
		AND I.SYNC_UNUSED_DAY >= @unused_day
		AND I.REG_DATE = @REG_DATE

END
ELSE 
BEGIN
	
		
		-- 추가되는 Index 에 대해서 Hint 찾는 Buffer에 추가 함. 
		-- 매일 조건에 맞는 데이터를 추가로 Insert 하기 때문
		INSERT INTO TMP_NOUSED_TARGET_INDEX
		(SEQNO, SERVER_ID, DATABASE_NAME, OBJECT_NAME, INDEX_ID, INDEX_NAME, SEARCH_YN )
		SELECT DISTINCT  I.SEQNO, I.SERVER_ID, I.DATABASE_NAME, I.OBJECT_NAME, I.INDEX_ID, I.INDEX_NAME, 'N' AS SEARCH_YN 
		FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
			JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
			LEFT JOIN TMP_NOUSED_TARGET_INDEX AS T WITH(NOLOCK) ON T.SEQNO = I.SEQNO
		WHERE DEL_PROC_TARGET = 'Y'
			AND S.SITE_GN = @SITE_GN
			AND I.UNUSED_DAY >= @unused_day 
			AND I.SYNC_UNUSED_DAY >=@unused_day
			AND T.SEQNO  IS NULL
			AND I.REG_DATE = @REG_DATE
	
END

-- 타켓이 변한 인덱스는 대상에서 삭제 
DELETE P
	FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
		JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
			JOIN NOUSED_TARGET_PROCEDURE AS P WITH(NOLOCK) ON I.SEQNO = P.SEQNO
	WHERE DEL_PROC_TARGET = 'N'
		AND S.SITE_GN = @SITE_GN
		
DELETE T
	FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
		JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
		JOIN TMP_NOUSED_TARGET_INDEX AS T WITH(NOLOCK) ON T.SEQNO = I.SEQNO
	WHERE DEL_PROC_TARGET = 'N'
		AND S.SITE_GN = @SITE_GN


SELECT TOP (1) @I = I.ID 
FROM TMP_NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
	JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE I.SEARCH_YN = 'N' AND S.SITE_GN =@SITE_GN 
ORDER BY ID 

SELECT @TOT_COUNT= MAX(I.ID) 
FROM TMP_NOUSED_TARGET_INDEX  AS I WITH(NOLOCK) 
JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
WHERE S.SITE_GN =@SITE_GN


WHILE ( @I <= @TOT_COUNT )
BEGIN

			UPDATE I
				SET START_TIME = GETDATE(),
					@SERVER_ID = I.SERVER_ID, @INDEX_NAME = I.INDEX_NAME, @SEQ_NO=SEQNO

			FROM TMP_NOUSED_TARGET_INDEX AS I WITH(NOLOCK)
				JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
			WHERE  S.SITE_GN =@SITE_GN   AND ID = @I

			SELECT @SERVER_ID = I.SERVER_ID, @INDEX_NAME = I.INDEX_NAME, @SEQ_NO =SEQNO, @OBJECT_NAME = OBJECT_NAME
			FROM TMP_NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
				JOIN SERVERINFO AS S WITH(NOLOCK) ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
			WHERE  S.SITE_GN =@SITE_GN   AND ID = @I


			IF @INDEX_NAME IS NULL CONTINUE; -- 다른 사이트 DATA 일 경우
	   
	        -- , 들어간 Object Name 수정
			SET @OBJECT_NAME = REPLACE(@OBJECT_NAME,', ','')

			INSERT INTO NOUSED_TARGET_PROCEDURE 
			( REF_TYPE, SEQNO, REG_DATE, SCRIPT_NO, SERVER_ID, DATABASE_NAME, OBJECT_ID, OBJECT_NAME, SCHEMA_NAME, UPD_DATE)
			SELECT 'I' AS REF_TYPE, @SEQ_NO ,@REG_DATE AS REG_DATE, D.SCRIPT_SEQ, D.SERVER_ID, D.DATABASE_NAME, D.OBJECT_ID, D.OBJECT_NAME, SCHEMA_NAME, GETDATE() 
			FROM dbo.DBA_SCRIPT_ARCHIVE_DATA AS D WITH(NOLOCK) 
				 JOIN SERVERINFO AS S ON D.SERVER_ID=S.SERVER_ID AND S.USE_YN = 'Y'
			WHERE S.SITE_GN = @site_gn
				AND D.SERVER_ID = @SERVER_ID
				AND  contains(D.UNCOMM_SCRIPT, @INDEX_NAME)  -- FULL TEXT 이용
				AND  contains(D.UNCOMM_SCRIPT, @OBJECT_NAME)


		
		UPDATE TMP_NOUSED_TARGET_INDEX SET SEARCH_YN= 'Y' ,end_time = GETDATE() WHERE ID = @I
		SET @I = @I + 1
END

-- 호출 정보 갱신 
update  n
	set CALL_ACML_DAY = q.call_day, unused_day = q.unused_day
from NOUSED_TARGET_PROCEDURE  as n with(nolock) 
 join query_stats_usage as q with(nolock) on n.SCRIPT_NO = q.SCRIPT_SEQ  


--싱크 호출 정보
update  n
	set SYNC_CALL_ACML_DAY = q.call_day
from NOUSED_TARGET_PROCEDURE  as n with(nolock) 
	join db_synk as d with(nolock) on n.server_id = d.server_id and n.database_name  = d.db_name
	join query_stats_usage as q with(nolock) on d.sync_server_id = q.server_id and n.database_name = q.database_name and n.object_name = q.object_name







