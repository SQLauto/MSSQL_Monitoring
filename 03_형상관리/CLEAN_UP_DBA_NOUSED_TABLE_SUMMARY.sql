/*************************************************************************  
* 프로시저명: DBO.UP_DBA_NOUSED_TABLE_SUMMARY
* 작성정보	: 2015-03-02 BY CHOI BO RA
* 관련페이지:  
* 내용		:  NOUSED_TARGET_TABLE 대상 SELECT

* 수정정보	: EXEC UP_DBA_NOUSED_TABLE_SUMMARY 'G', 0
**************************************************************************/
ALTER PROCEDURE DBO.UP_DBA_NOUSED_TABLE_SUMMARY
	 @SITE_GN  CHAR(1) = 'G', 
	 @SERVER_ID INT  =0
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */
DECLARE @REG_DATE DATE

SELECT @REG_DATE =  REG_DATE  FROM NOUSED_TARGET_TABLE_LOG WHERE SITE_GN = @SITE_GN AND PROCESS_TYPE  IN ('S', 'C')

/*BODY*/
	
	

	SELECT (CASE WHEN convert(nvarchar(10),I.REG_DATE, 121) IS NULL  and s.server_name is null  THEN 'Total SUM' ELSE convert(nvarchar(10),I.REG_DATE, 121) END) AS REG_DATE,
		(CASE WHEN S.SERVER_NAME IS NULL  and convert(nvarchar(10),I.REG_DATE, 121) IS not null THEN '일자 별 SUM' ELSE S.SERVER_NAME END)   AS SERVER_NAME, 
		SUM(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN 1 ELSE 0  END  ) AS EXPECTANCY_COUNT, 
		SUM(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN M.RESERVED ELSE 0  END ) /1024  AS EXPECTANCY_SIZE_MB, 
		SUM(CASE WHEN I.DEL_YN = 'Y' THEN 1 ELSE 0 END  )  AS EXECUTION_COUNT,
		SUM(CASE WHEN I.DEL_YN = 'Y' THEN M.RESERVED ELSE 0 END  ) /1024 AS EXECUTION_SIZE_MB
			
	FROM NOUSED_TARGET_TABLE AS I WITH(NOLOCK) 
		JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
		LEFT JOIN TABLE_VINFO_MASTER AS M WITH(NOLOCK) ON I.SERVER_ID = M.SERVER_ID AND I.DATABASE_NAME = M.DB_NAME AND I.OBJECT_NAME = M.TABLE_NAME
	WHERE DEL_PROC_TARGET = 'Y'  AND S.SITE_GN = @SITE_GN
	AND I.SERVER_ID = CASE WHEN @SERVER_ID = 0 THEN I.SERVER_ID ELSE @SERVER_ID END
	AND I.REG_DATE <=@REG_DATE
	GROUP BY I.REG_DATE, S.SERVER_NAME  WITH ROLLUP
	
	ORDER BY convert(nvarchar(10),I.REG_DATE, 121), S.SERVER_NAME


