
/*************************************************************************  
* 프로시저명: dbo.up_dba_noused_target_index_summary
* 작성정보	: 2015-03-02 by choi bo ra
* 관련페이지:  
* 내용		:  NOUSED_TARGET_INDEX 대상 SELECT

* 수정정보	: EXEC up_dba_noused_target_index_summary 'G', 0
**************************************************************************/
ALTER PROCEDURE dbo.up_dba_noused_index_summary
	 @SITE_GN  CHAR(1) = 'G', 
	 @SERVER_id int  = 0
AS

/* COMMON DECLARE */
SET NOCOUNT ON

/* USER DECLARE  */

DECLARE @REG_DATE DATE

SELECT top 1 @REG_DATE =  REG_DATE  FROM NOUSED_TARGET_INDEX_LOG WHERE SITE_GN = @SITE_GN 



/*BODY*/

	SELECT (CASE WHEN convert(nvarchar(10),I.REG_DATE, 121) IS NULL  and s.server_name is null  THEN 'Total SUM' ELSE convert(nvarchar(10),I.REG_DATE, 121) END) AS REG_DATE,
		(CASE WHEN S.SERVER_NAME IS NULL  and convert(nvarchar(10),I.REG_DATE, 121) IS not null THEN '일자 별 SUM' ELSE S.SERVER_NAME END)   AS SERVER_NAME, 
		SUM(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN 1 ELSE 0  end  ) AS EXPECTANCY_COUNT, 
		sum(CASE WHEN I.DEL_PROC_TARGET = 'Y' THEN size ELSE 0  end ) /1024  AS EXPECTANCY_SIZE_MB, 
		SUM(CASE WHEN I.DEL_YN = 'Y' THEN 1 ELSE 0 END  )  AS EXECUTION_COUNT,
		sum(CASE WHEN I.DEL_YN = 'Y' THEN size ELSE 0 END  ) /1024 AS EXECUTION_SIZE_MB
			
	FROM NOUSED_TARGET_INDEX AS I WITH(NOLOCK) 
		JOIN SERVERINFO AS S WITH(NOLOCK)  ON I.SERVER_ID = S.SERVER_ID AND S.USE_YN = 'Y'
	WHERE DEL_PROC_TARGET = 'Y'  AND S.site_gn = @SITE_GN
	and i.server_id = case when @server_id = 0 then i.server_id else @server_id end
	and i.reg_date >= dateadd(yy,-1,@REG_DATE )
	GROUP BY I.REG_DATE, S.SERVER_NAME  WITH ROLLUP
	ORDER BY I.REG_DATE  desc , S.SERVER_NAME



